$env.POWERLINE_COMMAND = 'oh-my-posh'
$env.PROMPT_INDICATOR = ""
$env.POSH_SESSION_ID = "fc4b54b0-2293-41d7-acf8-8fcc06fa6ea3"
$env.POSH_SHELL = "nu"
$env.POSH_SHELL_VERSION = (version | get version)
let posh_dir = (realpath (which oh-my-posh | get 0 | get path)) | path dirname | path dirname
let posh_theme = $'($posh_dir)/share/oh-my-posh/themes/devious-diamonds.omp.yaml'
$env.POSH_THEME = $"($posh_theme)"

# disable all known python virtual environment prompts
$env.VIRTUAL_ENV_DISABLE_PROMPT = 1
$env.PYENV_VIRTUALENV_DISABLE_PROMPT = 1

let _omp_executable: string = (realpath (which oh-my-posh | get 0 | get path))

# PROMPTS
def --env posh_context [] {
    $env.config.render_right_prompt_on_last_line = false
}

$env.SET_POSHCONTEXT = posh_context

def --env --wrapped _omp_get_prompt [
    type: string,
    ...args: string
] {
    mut execution_time = -1
    mut no_status = true
    # We have to do this because the initial value of `$env.CMD_DURATION_MS` is always `0823`, which is an official setting.
    # See https://github.com/nushell/nushell/discussions/6402#discussioncomment-3466687.
    if $env.CMD_DURATION_MS != '0823' {
        $execution_time = $env.CMD_DURATION_MS
        $no_status = false
    }
    $env.config.render_right_prompt_on_last_line = false

    (
        ^$_omp_executable print $type
            --save-cache
            --shell=nu
            $"--shell-version=($env.POSH_SHELL_VERSION)"
            $"--status=($env.LAST_EXIT_CODE)"
            $"--no-status=($no_status)"
            $"--execution-time=($execution_time)"
            $"--terminal-width=((term size).columns)"
            $"--job-count=(job list | length)"
            ...$args
    )
}

$env.PROMPT_MULTILINE_INDICATOR = (
    ^$_omp_executable print secondary
        --shell=nu
        $"--shell-version=($env.POSH_SHELL_VERSION)"
)

$env.PROMPT_COMMAND = {||
    # hack to set the cursor line to 1 when the user clears the screen
    # this obviously isn't bulletproof, but it's a start
    mut clear = false
    if $nu.history-enabled {
        $clear = (history | is-empty) or ((history | last 1 | get 0.command) == "clear")
    }

    if ($env.SET_POSHCONTEXT? | is-not-empty) {
        do --env $env.SET_POSHCONTEXT
    }

    _omp_get_prompt primary $"--cleared=($clear)"
}

$env.PROMPT_COMMAND_RIGHT = null
$env.config.render_right_prompt_on_last_line = false
set-env $env.config.render_right_prompt_on_last_line false
$env.config | merge { render_right_prompt_on_last_line: false } | load-env
