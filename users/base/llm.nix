{...}: {
  home.sessionVariables = {OLLAMA_HOST = "yew.local";};
  programs.claude-code = {
    enable = true;
    settings = {
      model = "qwen3.5:27b";
      env = {
        ANTHROPIC_BASE_URL = "http://yew.local:11434";
        ANTHROPIC_AUTH_TOKEN = "ollama";
      };
    };
  };
}
