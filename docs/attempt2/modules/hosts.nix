# Host and user definitions
# Each host can have multiple users, each user gets home-manager integration
{
  # WSL instance - x86_64
  den.hosts.x86_64-linux.wsl.users.paul = { };

  # Laptop - x86_64 (adjust architecture if needed)
  den.hosts.x86_64-linux.laptop.users.paul = { };

  # Raspberry Pi media server - aarch64
  den.hosts.aarch64-linux.rpi.users.paul = { };

  # You can also define standalone home-manager configurations (no NixOS)
  # den.homes.x86_64-linux.paul = { };
}
