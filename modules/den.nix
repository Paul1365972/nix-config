{ inputs, ... }:
{
  den.hosts.aarch64-linux.darkness = {
    form = "embedded";
    users.paul = { };
  };

  den.hosts.x86_64-linux.phos-wsl = {
    form = "wsl";
    wsl.enable = true;
    users.paul = { };
  };

  den.hosts.x86_64-linux.phos = {
    form = "laptop";
    users.paul = { };
  };

  den.hosts.x86_64-linux.saber = {
    form = "server";
    users.paul = { };
  };
}
