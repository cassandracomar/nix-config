module eat {
  export def --env enable_integration [] {
    if $nu.is-interactive and 'EAT_SHELL_INTEGRATION_DIR' in $env and ($env.TERM | str starts-with "eat-") {
      enable_integration_impl
    }
  }

  # Tell eat where the nushell history file lives so it can populate its line-mode
  # input ring directly.  Protocol (see eat.el `eat--get-shell-history`):
  #   shell -> eat: OSC 51 e;I;0 ; <format> ; <host-b64> ; <path-b64> ST
  #   eat  -> shell: OSC 51 e;I;0 ST                (file readable here -- handled)
  #               or OSC 51 e;I;<ring-size> ST     (need shell to send entries via e;I;1)
  # We only ever run in the same host as eat with a readable history file, so the
  # `e;I;0` path always applies; eat reads the file directly and returns 0.
  # `term query` blocks for the reply so it gets consumed instead of leaking onto
  # reedline as stray bytes.
  export def history_file [] {
    # `hostname` outputs a trailing newline; eat's `(string= host (system-name))`
    # check fails if we include it, which makes eat fall back to the
    # "ask the shell to send N entries" path instead of reading the file directly.
    let host = (hostname | str trim)
    let notice = notify "51;e;I;0" $"bash;($host | encode base64);($nu.history-path | encode base64)"
    term query $notice --prefix (ansi escape) --terminator (ansi st) | ignore
  }

  def --env enable_integration_impl [] {
    # wrap the prompt in the appropriate osc codes for eat
    let old_prompt_command = $env.PROMPT_COMMAND
    $env.PROMPT_COMMAND = {||
      let prompt_notification = notify "51;e" "J"
      let old_prompt = do $old_prompt_command
      let prompt_header = notify "51;e" "B"
      let prompt_footer = notify "51;e" "C"
      $"($prompt_notification)($prompt_header)($old_prompt)($prompt_footer)"
    }

    # wrap continuation lines in their osc codes
    let old_ml_prompt = $env.PROMPT_MULTILINE_INDICATOR
    $env.PROMPT_MULTILINE_INDICATOR = $"(notify '51;e' 'D')($old_ml_prompt)(notify '51;e' 'E')"
    $env.PROMPT_COMMAND_RIGHT = null

    # hand eat the history file path so it can populate its input ring directly
    history_file

    # set up hooks to handle notifications to eat
    #
    # Hook bodies must `print -n` the `notify` return value: the closure's return
    # is ignored by nushell's hook runner, so an unprinted OSC string is silently
    # discarded and the corresponding eat handler (eat--pre-cmd / eat--set-cmd /
    # eat--set-cmd-status) never fires.  The PROMPT_COMMAND wrap above works
    # without `print` because its closure return is *the* prompt text written to
    # the terminal.
    $env.config = {
      hooks: {
        pre_execution: [
          {||
            let full_command = (commandline | split words)
            if ($full_command | length) > 0 {
              let command = ($full_command | get 0 | encode base64)
              print -n (notify '51;e;F' $command)
              print -n (notify '51;e' "G")
              print -n (title_notice)
            }
          }
        ]
        # using `pre_prompt` as a postexec hook -- make sure this hook is run before all others
        pre_prompt: [
          {||
            # send the exit code notice
            let exit_code = $"($env.LAST_EXIT_CODE)"
            print -n (notify '51;e;H' $exit_code)
            print -n (title_notice)
          }
          ...$env.config.hooks.pre_prompt
        ]
      },
      render_right_prompt_on_last_line: false,
    }
  }

  # send a notification to eat, properly inserting escape sequences to denote the start and end
  # of messages.
  export def notify [code, msg] {
    # `ansi --osc` emits the OSC introducer (ESC `]`) plus the code; `ansi st`
    # emits the String Terminator (ESC `\`). Do NOT wrap with `ansi --escape`
    # or prepend `ansi escape_left` -- both inject a spurious CSI introducer
    # (ESC `[`) ahead of the OSC, which puts eat's parser into CSI state and
    # silently swallows the OSC dispatch (eat--handle-uic never fires, so
    # auto-line-mode and shell prompt annotation never engage).
    $"(ansi --osc $code);($msg)(ansi st)"
  }

  # Send a command to eat
  export def send [
    handler: string # eat handler to invoke
    ...args: string # handler arguments
  ] {
    let msg_command = $"($handler | encode base64)"
    let msg_args = $args | each {|arg|
      $"($arg | encode base64)"
    }
    notify "51;e;M" $'($msg_command);($msg_args | str join ";")'
  }

  # open a file in emacs
  export def open [
    filepath: path # file to open
  ] {
    send "open" $filepath
  }

  # invoke a magit command
  export def "magit" [
    command: string
    ...args: string
  ] {
    send "git" $command ...($args)
  }

  # tee piped input into an emacs buffer (eshell's `>#<buffer>' equivalent)
  #
  # Reads stdin, sends a base64-wrapped copy to the running Emacs to be
  # written into BUFFER (created if needed), and passes the original data
  # through so it can continue down the pipeline or be displayed.  By
  # default the buffer is REPLACED on each invocation, matching POSIX
  # tee; pass --append (-a) to accumulate output across runs.
  # Examples:
  #   ls | eat tee "*ls-results*"
  #   ^cargo build 2>&1 | eat tee -a "*build-log*"
  #   open log.json | eat tee "*log*" | get errors
  export def tee [
    buffer: string  # emacs buffer name
    --append (-a)   # append to buffer instead of replacing its contents
  ] {
    let data = $in
    let data_str = if ($data | describe | str starts-with "string") {
      $data
    } else {
      $data | to text
    }
    let mode = if $append { "append" } else { "replace" }
    print -n (send "tee" $buffer $mode $data_str)
    $data
  }

  # cat the contents of an emacs buffer as a stream
  #
  # Inverse of `tee' -- requests BUFFER's contents from the running emacs
  # via an OSC roundtrip, decodes the base64 payload it sends back, and
  # writes the result to stdout so it can flow into the next pipeline
  # stage.  Empty string when the buffer doesn't exist.
  # Examples:
  #   eat cat "*build-log*" | grep -i error
  #   eat cat "*scratch*" | from json
  export def cat [
    buffer: string # emacs buffer name (e.g. "*build-log*")
  ] {
    let request = notify "51;e;M" $"('cat' | encode base64);($buffer | encode base64)"
    # Reply format: ]51;e;K;<base64-content>  (prefix `(ansi escape)` stripped,
    # terminator `(ansi st)` stripped).  Split by `;', element 3 is the b64.
    let raw = term query $request --prefix (ansi escape) --terminator (ansi st)
    let parts = $raw | bytes split ';'
    let b64 = $parts | get 3 | decode utf-8
    $b64 | decode base64 | decode utf-8
  }

  # update the eat terminal title
  export def title_notice [] {
    # this is technically `ansi title` but the `notify` function would insert the
    # `escape_left` sequence before reinserting it as part of `ansi title` so
    # just including it as a sting here.
    let title_notice = "2"
    let user = $env.USER
    let hostname = (hostname)
    let pwd = ($env.PWD | str replace $nu.home-dir '~')
    let user_indicator = if $user == "root" {
      r#'\#'#
    } else {
      r#'$'#
    }
    notify $title_notice $"($user)@($hostname):($pwd)($user_indicator)"
  }
}

use eat

eat enable_integration

# add a `find-file` command to open files the usual way
# you'll need to add an `open` handler to `eat-message-handler-alist`
# i.e. --
#   (defun +eat/nu-open (&rest args)
#    (interactive)
#    (cl-callf find-file (car args) (cdr args)))
#  (add-to-list 'eat-message-handler-alist '("open" . +eat/nu-open))
alias find-file = eat open

export def "git status" [...args: string] {
  eat magit status ...($args)
}

export def "git log" [...args: string] {
  eat magit log ...($args)
}

# there are also probably other useful aliases/handlers one could add
# -- e.g. using emacs' native manpage render for manpages.
# I'll probably create an `eat-nushell` package to handle these.

# the right prompt being on the input line breaks `eat-line-mode` as everything in between
# the left and right prompts is treated as uneditable whitespace.
#
# multiline prompts continue to show the right prompt on the first line but this turns it
# off completely for single-line prompts.
$env.config | merge { render_right_prompt_on_last_line: false } | load-env
{ PROMPT_COMMAND_RIGHT: null } | load-env
