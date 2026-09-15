{
  den.aspects.saber.provides.backup.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      settings = config.saber.backup;
      state = "/var/lib/saber-backup";
      pause = pkgs.writeShellApplication {
        name = "backup-pause";
        runtimeInputs = [
          pkgs.systemd
          pkgs.coreutils
        ];
        text = ''
          prepareHooks=(${lib.escapeShellArgs (map lib.getExe settings.prepare)})
        ''
        + builtins.readFile ./backup/pause.sh;
      };
      resume = pkgs.writeShellApplication {
        name = "backup-resume";
        runtimeInputs = [
          pkgs.systemd
          pkgs.coreutils
        ];
        text = ''
          resumeHooks=(${lib.escapeShellArgs (map lib.getExe settings.resume)})
        ''
        + builtins.readFile ./backup/resume.sh;
      };
      resumeCommand = "${lib.getExe resume} ${state}";
    in
    {
      options.saber.backup = {
        units = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Application services and timers paused while their state is archived.";
        };
        prepare = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Preparation commands receiving the backup state directory as their argument.";
        };
        resume = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Idempotent recovery commands receiving the backup state directory as their argument.";
        };
      };

      config = {
        saber.backup.units = [
          "comin.service"
          "auto-reboot.timer"
        ];
        services.borgbackup.jobs.hdd = {
          repo = "/mnt/hdd/backup/saber";
          encryption.mode = "none";
          compression = "zstd";
          startAt = "*-*-* 03:30:00";
          readWritePaths = [ state ];
          preHook = ''
            ${resumeCommand}
            ${lib.getExe pause} ${state} ${lib.escapeShellArgs (lib.unique settings.units)}
          '';
          postCreate = resumeCommand;
          postHook = resumeCommand;
          prune.keep = {
            daily = 7;
            weekly = 4;
            monthly = 6;
          };
        };
        systemd.services.borgbackup-job-hdd = {
          serviceConfig = {
            StateDirectory = "saber-backup";
            StateDirectoryMode = "0700";
            ExecStopPost = resumeCommand;
          };
        };
        systemd.services.backup-recovery = {
          description = "Restore applications after an interrupted backup";
          wantedBy = [ "multi-user.target" ];
          wants = [ "postgresql.target" ];
          after = [ "postgresql.target" ];
          before = [ "borgbackup-job-hdd.service" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = resumeCommand;
          };
        };
      };
    };
}
