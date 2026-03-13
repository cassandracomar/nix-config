{...}: {
  home.sessionVariables = {OLLAMA_HOST = "yew.local";};
  programs.claude-code = {
    enable = true;
    settings = {
      model = "qwen3.5:35b-UD-IQ3_XXS";
      env = {
        ANTHROPIC_BASE_URL = "http://yew.local:8001";
        ANTHROPIC_API_KEY = "sk-no-key-required";
        ANTHROPIC_AUTH_TOKEN = "";
        CLAUDE_CODE_ENABLE_TELEMETRY = "0";
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
        CLAUDE_CODE_ATTRIBUTION_HEADER = "0";
      };
      promptSuggestionEnabled = false;
      attribution = {
        commit = "";
        pr = "";
      };
      prefersReducedMotion = true;
      terminalProgressBarEnabled = false;
      effortLevel = "high";
    };
  };
}
