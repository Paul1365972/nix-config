{ ... }:
{
  den.aspects.auto-upgrade.nixos = {
    system.autoUpgrade = {
      enable = true;
      flake = "github:Paul1365972/nix-config";
      flags = [
        "--refresh"
        "-L"
      ];
      dates = "04:00";
      randomizedDelaySec = "30min";
    };
  };
}
