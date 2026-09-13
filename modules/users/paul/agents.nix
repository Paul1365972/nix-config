_: {
  den.aspects.agents.provides.to-users.homeManager = {
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
