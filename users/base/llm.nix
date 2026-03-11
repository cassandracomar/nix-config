{...}: {
  programs.claude-code = {
    enable = true;
    settings = {
      model = "qwen3-coder-next:80b-128k";
      env = {
        ANTHROPIC_BASE_URL = "https://yew.local:11134";
        ANTHROPIC_API_KEY = "";
        ANTHROPIC_AUTH_TOKEN = "ollama";
      };
    };
  };
}
