{ inputs, ... }:
{
  den.aspects.saber.provides.backups = {
    nixos =
      { config, ... }:
      {
        services.restic.backups.saber-state = {
          paths = [
            "/var/lib"
            "/var/backup/postgresql"
          ];
          environmentFile = config.sops.secrets.restic-env.path;
          passwordFile = config.sops.secrets.restic-password.path;
          repositoryFile = config.sops.secrets.restic-repository.path;
          timerConfig = {
            OnCalendar = "03:00";
            Persistent = true;
          };
          pruneOpts = [
            "--keep-daily 7"
            "--keep-weekly 4"
            "--keep-monthly 6"
          ];
          exclude = [
            "/var/lib/jellyfin/transcodes"
            "/var/lib/matrix-synapse/media_store"
            "/var/lib/private/tailscale"
          ];
        };

        sops.secrets.restic-env = {
          sopsFile = inputs.self + "/secrets/saber.yaml";
          mode = "0440";
        };
        sops.secrets.restic-password = {
          sopsFile = inputs.self + "/secrets/saber.yaml";
          mode = "0440";
        };
        sops.secrets.restic-repository = {
          sopsFile = inputs.self + "/secrets/saber.yaml";
          mode = "0440";
        };
      };
  };
}
