{...}: {
  home.sessionVariables = {OLLAMA_HOST = "yew.local";};
  programs.claude-code = {
    enable = true;
    settings = {
      model = "qwen3-coder-next:80b-128k";
      env = {
        ANTHROPIC_BASE_URL = "http://yew.local:11434";
        ANTHROPIC_AUTH_TOKEN = "ollama";
      };
    };
  };
}
