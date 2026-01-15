{ den, ... }:
{
  den.aspects.binfmt = {
    nixos = {
      # Enable QEMU binfmt for aarch64-linux cross-compilation
      # This allows building aarch64 packages on x86_64 systems
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
    };
  };
}
