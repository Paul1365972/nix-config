_: {
  den.aspects.agents.homeManager = {
    programs.claude-code = {
      enable = true;
      skills = ./skills;
    };

    programs.codex = {
      enable = true;
      skills = ./skills;
    };
  };
}
