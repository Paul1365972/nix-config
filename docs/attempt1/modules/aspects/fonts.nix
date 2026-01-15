{ ... }:
{
  flake.modules.nixos.fonts = { pkgs, ... }: {
    fonts.packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono  # Used in terminal.nix
    ];
  };
}
