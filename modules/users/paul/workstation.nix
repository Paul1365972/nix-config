{ den, ... }:
{
  den.aspects.workstation-user.includes = [
    den.aspects.ssh-identities
    den.aspects.agents
  ];
}
