_: {
  # rustup over nixpkgs rustc so each project's rust-toolchain.toml governs;
  # downloaded toolchains run via nix-ld (den.aspects.nix-development).
  den.aspects.rust.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        rustup
        gcc
      ];
    };
}
