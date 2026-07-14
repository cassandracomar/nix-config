$env.POWERLINE_COMMAND = 'oh-my-posh'
$env.PROMPT_INDICATOR = ""
$env.POSH_SESSION_ID = "fc4b54b0-2293-41d7-acf8-8fcc06fa6ea3"
$env.POSH_SHELL = "nu"
$env.POSH_SHELL_VERSION = (version | get version)

# Resolve the upstream `devious-diamonds` theme bundled with oh-my-posh.
# oh-my-posh does NOT read $env.POSH_THEME -- the config must be passed via
# `--config` on every invocation; without it, oh-my-posh silently falls back
# to its built-in default theme (single line, right-aligned git block bleeds
# into the input area).
let posh_dir = (realpath (which oh-my-posh | get 0 | get path)) | path dirname | path dirname
let _posh_theme: string = $'($posh_dir)/share/oh-my-posh/themes/devious-diamonds.omp.yaml'
$env.POSH_THEME = $_posh_theme

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
    let execution_time = match $env.CMD_DURATION_MS {
        '0823' => -1
        $ms => { $ms | into int }
    }
    $env.config.render_right_prompt_on_last_line = false

    (
        ^$_omp_executable print $type
            --config $env.POSH_THEME
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
        --config $env.POSH_THEME
        --shell=nu
        $"--shell-version=($env.POSH_SHELL_VERSION)"
)

$env.PROMPT_COMMAND = {||
    # hack to set the cursor line to 1 when the user clears the screen
    # this obviously isn't bulletproof, but it's a start
    let clear = $nu.history-enabled and (
        (history | is-empty)
        or (history | last | get command?) == "clear"
    )

    if ($env.SET_POSHCONTEXT? | is-not-empty) {
        do --env $env.SET_POSHCONTEXT
    }

    _omp_get_prompt primary $"--cleared=($clear)"
}

$env.PROMPT_COMMAND_RIGHT = null
$env.config.render_right_prompt_on_last_line = false
$env.config | merge { render_right_prompt_on_last_line: false } | load-env
