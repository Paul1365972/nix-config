{ ... }:
{
  den.aspects.saber.provides.redis = {
    nixos = {
      # Authentik gets its own instance; Nextcloud's is provisioned automatically by services.nextcloud.configureRedis.
      services.redis.servers.authentik = {
        enable = true;
      };
    };
  };
}
