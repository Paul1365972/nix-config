{ ... }:
{
  # rustup over nixpkgs rustc so each project's rust-toolchain.toml governs;
  # downloaded toolchains run via nix-ld (den.aspects.nix-dev).
  den.aspects.rust.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        rustup
        gcc
      ];
    };
}
