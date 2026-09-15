{
  den.aspects.saber.nixos =
    { config, lib, ... }:
    let
      tailscale = lib.getExe config.services.tailscale.package;
      serve =
        name: key: target:
        let
          port = lib.removePrefix "tcp:" key;
          listener = if lib.hasPrefix "tcp://" target then "--tcp=${port}" else "--https=${port}";
        in
        "${tailscale} serve --service=svc:${name} ${listener} ${target}";
    in
    {
      services.tailscale.serve.enable = true;
      # set-config loses HTTPS termination for HTTP backends (tailscale/tailscale#18381).
      systemd.services.tailscale-serve.serviceConfig.ExecStart = lib.mkForce (
        [ "${tailscale} serve reset" ]
        ++ lib.concatLists (
          lib.mapAttrsToList (
            name: service: lib.mapAttrsToList (serve name) service.endpoints
          ) config.services.tailscale.serve.services
        )
      );
    };
}
