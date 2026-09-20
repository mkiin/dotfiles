{
  programs.starship = {
    enable = true;

    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      format = "$directory$git_branch$character";

      directory = {
        truncation_length = 3;
      };

      git_branch = {
        format = "[$symbol$branch]($style) ";
      };

      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
    };
  };
}
