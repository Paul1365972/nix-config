# Named visual styles for the desktop. Each rice is built as a NixOS
# specialisation so `rice <name>` switches live without a full rebuild.
{ lib, ... }:
let
  rices = {
    tokyo = {
      label = "Tokyo Night";
      colors = {
        bg = "1a1b26";
        fg = "c0caf5";
        accent = "7aa2f7";
        alt = "bb9af7";
      };
      font = "JetBrainsMono Nerd Font";
    };
    kanagawa = {
      label = "Kanagawa";
      colors = {
        bg = "1f1f28";
        fg = "dcd7ba";
        accent = "7e9cd8";
        alt = "957fb8";
      };
      font = "JetBrainsMono Nerd Font";
    };
    rosepine = {
      label = "Rose Pine";
      colors = {
        bg = "191724";
        fg = "e0def4";
        accent = "c4a7e7";
        alt = "ebbcba";
      };
      font = "JetBrainsMono Nerd Font";
    };
  };
  defaultRice = "tokyo";
in
{
  den.aspects.rice.nixos =
    { config, pkgs, ... }:
    {
      options.rice = {
        active = lib.mkOption {
          type = lib.types.enum (lib.attrNames rices);
          default = defaultRice;
        };
        current = lib.mkOption {
          type = lib.types.attrs;
          readOnly = true;
        };
        available = lib.mkOption {
          type = lib.types.attrs;
          readOnly = true;
          default = rices;
        };
      };

      config = {
        rice.current = rices.${config.rice.active};

        # inheritParentConfig keeps the rest of the system identical so each
        # specialisation only swaps the rice-dependent bits.
        specialisation = lib.mapAttrs' (
          name: _:
          lib.nameValuePair "rice-${name}" {
            inheritParentConfig = true;
            configuration = {
              rice.active = lib.mkForce name;
            };
          }
        ) (lib.filterAttrs (n: _: n != config.rice.active) rices);

        environment.systemPackages = [
          (pkgs.writeShellApplication {
            name = "rice";
            text = ''
              avail=${lib.concatStringsSep " " (lib.attrNames rices)}
              current=${config.rice.active}

              usage() {
                echo "usage: rice [list | current | <name>]"
                echo "  available: $avail"
                exit 1
              }

              [ "$#" -ge 1 ] || usage

              case "$1" in
                list)
                  for r in $avail; do
                    if [ "$r" = "$current" ]; then echo "* $r"; else echo "  $r"; fi
                  done
                  ;;
                current)
                  echo "$current"
                  ;;
                "$current")
                  echo "already on $current"
                  ;;
                *)
                  if ! printf '%s\n' $avail | grep -qx "$1"; then
                    echo "unknown rice: $1" >&2; usage
                  fi
                  spec=/run/current-system/specialisation/rice-"$1"
                  [ -d "$spec" ] || { echo "specialisation rice-$1 not built — run nh os switch first" >&2; exit 1; }
                  sudo "$spec"/bin/switch-to-configuration test
                  ;;
              esac
            '';
          })
        ];
      };
    };
}
