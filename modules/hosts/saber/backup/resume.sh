state="$1"
[[ -d "$state" ]] || exit 0
status=0

for hook in "${resumeHooks[@]}"; do
  "$hook" "$state" || status=1
done

shopt -s nullglob
records=("$state"/active/*)
units=()
for record in "${records[@]}"; do
  units+=("${record##*/}")
done
if (( ${#units[@]} )); then
  if systemctl start "${units[@]}"; then
    rm -- "${records[@]}"
  else
    status=1
  fi
fi
exit "$status"
