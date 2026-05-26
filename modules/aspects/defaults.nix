{ den, lib, ... }:
{
  den.default = {
    nixos.system.stateVersion = "26.05";
    homeManager.home.stateVersion = "26.05";
    includes = [
      den.batteries.define-user
      den.batteries.hostname
    ];
  };

  # mkDefault so a service-account user can opt out via users.<name>.classes = [ "user" ].
  den.schema.user.classes = lib.mkDefault [
    "user"
    "homeManager"
  ];

  den.schema.host =
    { lib, ... }:
    {
      options.form = lib.mkOption {
        type = lib.types.enum [
          "laptop"
          "desktop"
          "wsl"
          "embedded"
          "server"
        ];
        description = "Physical/runtime form of the host.";
      };
    };
}
