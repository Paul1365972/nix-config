{
  den.aspects.saber.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      tailscale = lib.getExe config.services.tailscale.package;
      services = config.services.tailscale.serve.services;
      serve =
        name: key: target:
        let
          port = lib.removePrefix "tcp:" key;
          listener = if lib.hasPrefix "tcp://" target then "--tcp=${port}" else "--https=${port}";
        in
        "${tailscale} serve --service=svc:${name} ${listener} ${target}";
      drainUnconfigured = pkgs.writeShellScript "tailscale-serve-drain-unconfigured" ''
        ${tailscale} debug prefs \
          | ${lib.getExe pkgs.jq} -r --argjson configured ${
            lib.escapeShellArg (builtins.toJSON (map (name: "svc:${name}") (lib.attrNames services)))
          } '(.AdvertiseServices // []) - $configured | .[]' \
          | while read -r service; do ${tailscale} serve drain "$service"; done
      '';
    in
    {
      services.tailscale.serve.enable = true;
      # set-config loses HTTPS termination for HTTP backends (tailscale/tailscale#18381).
      systemd.services.tailscale-serve.serviceConfig.ExecStart = lib.mkForce (
        [
          "${tailscale} serve reset"
          drainUnconfigured
        ]
        ++ lib.concatLists (
          lib.mapAttrsToList (name: service: lib.mapAttrsToList (serve name) service.endpoints) services
        )
      );
    };
}
