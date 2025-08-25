module eat {
  export def --env enable_integration [] {
    if $nu.is-interactive and 'EAT_SHELL_INTEGRATION_DIR' in $env and ($env.TERM | str starts-with "eat-") {
      enable_integration_impl
    }
  }

  # send eat the history file to ensure the emacs input ring and nushell's stay synced
  #
  # NOTE: this doesn't actually work. use `eat-line-load-input-history-from-file` in your emacs config instead.
  #       having the shell send the contents once on startup doesn't really make sense, anyway.
  export def history_file [] {
    let hist_file_notice = notify "51;e;I;0" $"bash;(hostname | encode base64);($nu.history-path | encode base64)"
    let raw_reply = term query $hist_file_notice --prefix (ansi escape) --terminator (ansi st)

    # the number of lines of history to provide is sent as the fourth element of the response
    let history_size = $raw_reply | bytes split ';' | get 3
    if $history_size != (0 | into binary) {
      # # there's not a function to do this and I don't want convert the number from binary by hand
      # # `print -r` does this properly but none of the other conversion functions handle raw binary properly
      let hist_size_text = nu -c $"\"($history_size | encode base64)\" | decode base64 | print -r"
      notify "51;e;I;1" $"bash;(tail -n $hist_size_text | ^base64 -w 0)"
    }
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

    # see the NOTE on the function on why this is commented out
    # history_file

    # set up hooks to handle notifications to eat
    $env.config = {
      hooks: {
        pre_execution: [
          {||
            let full_command = (commandline | split words)
            if ($full_command | length) > 0 {
              let command = ($full_command | get 0 | encode base64)
              let command_notice = '51;e;F'
              notify $command_notice $command

              let pre_exec_notice = '51;e;'
              notify $pre_exec_notice "G"

              title_notice
            }
          }
        ]
        # using `pre_prompt` as a postexec hook -- make sure this hook is run before all others
        pre_prompt: [
          {||
            # send the exit code notice
            let exit_code_notice = '51;e;H'
            let exit_code = $"($env.LAST_EXIT_CODE)"
            notify $exit_code_notice $exit_code

            title_notice
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
    # we need to insert the code as an `osc` code and use the `ansi` command
    # to prepare the `escape_left` and `sc` sequences or the command isn't properly
    # sent to the terminal -- rather portions of the message are rendered directly as output.
    let prefix = ansi --osc $code

    # we need to use `ansi` to escape the whole message, including the header and footer, for a similar reason
    ansi --escape $"(ansi escape_left)($prefix);($msg)(ansi st)"
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

  # Open a file in Emacs
  export def open [
    filepath: path # File to open
  ] {
    send "open" $filepath
  }

  # update the eat terminal title
  export def title_notice [] {
    # this is technically `ansi title` but the `notify` function would insert the
    # `escape_left` sequence before reinserting it as part of `ansi title` so
    # just including it as a sting here.
    let title_notice = "2"
    let user = $env.USER
    let hostname = (hostname)
    let pwd = ($env.PWD | str replace $nu.home-path '~')
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

# there are also probably other useful aliases/handlers one could add
# -- e.g. using emacs' native manpage render for manpages.
# I'll probably create an `eat-nushell` package to handle these.

# the right prompt being on the input line breaks `eat-line-mode` as everything in between
# the left and right prompts is treated as uneditable whitespace.
#
# multiline prompts continue to show the right prompt on the first line but this turns it
# off completely for single-line prompts.
{ config: { render_right_prompt_on_last_line: false } } | load-env
{ PROMPT_COMMAND_RIGHT: null } | load-env
