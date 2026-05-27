{ ... }:
{
  den.aspects.saber.provides.element = {
    nixos = {
      # Bakes config.json into pkgs.element-web; caddy.nix serves the resulting derivation.
      nixpkgs.config.element-web.conf = {
        default_server_config."m.homeserver" = {
          base_url = "https://matrix.1365972.xyz";
          server_name = "matrix.1365972.xyz";
        };
        brand = "Homeserver 1365972";
        disable_custom_urls = true;
        disable_guests = true;
      };
    };
  };
}
