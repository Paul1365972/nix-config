{
  den.aspects.saber.provides.caddy.nixos =
    { config, lib, ... }:
    let
      publicHostnames = map (lib.removePrefix "http://") (
        lib.filter (lib.hasPrefix "http://") (lib.attrNames config.services.caddy.virtualHosts)
      );
    in
    {
      services.caddy = {
        enable = true;
        globalConfig = ''
          default_bind 127.0.0.1 [::1]
          servers {
            trusted_proxies static 127.0.0.1/32 ::1/128
            client_ip_headers Cf-Connecting-Ip
          }
        '';
      };
      services.cloudflared.publicHosts = lib.genAttrs publicHostnames (_: "http://127.0.0.1:80");
    };
}
