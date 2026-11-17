$ErrorActionPreference = 'Stop'
$repository = Split-Path $PSScriptRoot
$qemu = "$env:ProgramFiles\qemu"
$state = "$env:LOCALAPPDATA\phos-preview"
$display = Get-CimInstance Win32_VideoController | Select-Object -First 1

$image = wsl --cd $repository -- nix build .#phos-preview --no-link --print-out-paths
if ($LASTEXITCODE) { throw 'Could not build the preview image' }

New-Item -ItemType Directory -Force $state | Out-Null
if ((Get-Content "$state\image" -ErrorAction SilentlyContinue) -ne $image) {
    $disk = wsl -- wslpath -u ("$state\phos.qcow2" -replace '\\', '/')
    wsl -- sh -c "cp --no-preserve=mode $image/*.qcow2 '$disk'"
    if ($LASTEXITCODE) { throw 'Could not copy the preview image' }
    Copy-Item "$qemu\share\edk2-i386-vars.fd" "$state\firmware-variables.fd" -Force
    Set-Content "$state\image" $image
}

Write-Host 'Ctrl+Alt+G releases the keyboard, Ctrl+Alt+F leaves fullscreen.'
& "$qemu\qemu-system-x86_64.exe" `
    -name phos -accel whpx -smp 8 -m 8G `
    -drive "if=pflash,format=raw,readonly=on,file=$qemu\share\edk2-x86_64-code.fd" `
    -drive "if=pflash,format=raw,file=$state\firmware-variables.fd" `
    -drive "if=virtio,format=qcow2,file=$state\phos.qcow2" `
    -device "virtio-vga-gl,xres=$($display.CurrentHorizontalResolution),yres=$($display.CurrentVerticalResolution)" `
    -display sdl,gl=core -full-screen `
    -device virtio-tablet-pci -device virtio-keyboard-pci `
    -device intel-hda -device hda-duplex `
    -nic user,model=virtio-net-pci
