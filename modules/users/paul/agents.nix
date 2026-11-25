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
        context = ./AGENTS.md;
        skills = ./skills;
      };

      programs.codex = {
        enable = true;
        context = ./AGENTS.md;
        skills = ./skills;
      };

      programs.antigravity-cli = {
        enable = true;
        context.AGENTS = ./AGENTS.md;
      };

      # agy ignores a skill whose folder or SKILL.md is a symlink, which is what `programs.antigravity-cli.skills` creates; a symlink to the whole skills folder works.
      home.file.".gemini/config/skills".source = ./skills;
    };
}
