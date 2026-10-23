_: {
  den.aspects.agents.homeManager =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        bun
        uv
      ];

      programs.claude-code = {
        enable = true;
        context = ./context.md;
        skills = ./skills;
      };

      programs.codex = {
        enable = true;
        context = ./context.md;
        skills = ./skills;
      };
    };
}
