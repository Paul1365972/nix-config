# Exposes the SD card image build for the darkness host
# Build with: nix build .#darkness-sd-image
{ inputs, ... }:
{
  perSystem =
    { ... }:
    {
      packages.darkness-sd-image =
        inputs.self.nixosConfigurations.darkness.config.system.build.sdImage;
    };
}
