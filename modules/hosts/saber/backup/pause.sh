state="$1"
shift
install -d -m 0700 "$state/active"

for unit in "$@"; do
  active=$(systemctl show --property=ActiveState --value "$unit")
  substate=$(systemctl show --property=SubState --value "$unit")
  if [[ "$active" =~ ^(active|activating|reloading)$ && "$substate" != exited ]]; then
    touch "$state/active/$unit"
  fi
done

for hook in "${prepareHooks[@]}"; do
  "$hook" "$state"
done

shopt -s nullglob
units=()
for record in "$state"/active/*; do
  units+=("${record##*/}")
done
if (( ${#units[@]} )); then
  systemctl stop "${units[@]}"
fi
systemctl start postgresqlBackup.service
