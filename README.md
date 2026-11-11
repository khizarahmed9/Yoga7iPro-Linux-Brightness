# Yoga 7i Pro Linux Brightness Fix

Brightness slider and keys do nothing on a Lenovo Yoga Pro 7 15IPH11 / Yoga 7i Pro (`83SN`, Intel `xe` + NVIDIA) running Linux. This fixes it with one kernel parameter.

## Fix it (2 minutes)

```bash
sudo bash fix-brightness.sh
reboot
```

Done. Press the brightness keys. The screen should dim.

> The script assumes the **limine** bootloader (CachyOS default). Other bootloader? See [Manual fix](#manual-fix).

## Still broken after reboot?

Try the next value. Reboot after each.

1. `sudo bash fix-brightness.sh 2` (force VESA interface)
2. `sudo bash fix-brightness.sh 3` (force Intel interface)

## Check it worked

```bash
cat /sys/class/backlight/intel_backlight/max_brightness
```

If the number is no longer `42667` (the old PWM value), DPCD is active.

## Undo

```bash
sudo sed -i '/xe.enable_dpcd_backlight=/d' /etc/default/limine
sudo limine-update
reboot
```

## Manual fix

Add this to your kernel command line:

```
xe.enable_dpcd_backlight=1
```

On limine (what the script does):

1. Add this line to `/etc/default/limine`:
   ```
   KERNEL_CMDLINE[default]+=" xe.enable_dpcd_backlight=1"
   ```
2. Run `sudo limine-update`
3. Reboot

On GRUB: add it to `GRUB_CMDLINE_LINUX_DEFAULT` in `/etc/default/grub`, run `sudo grub-mkconfig -o /boot/grub/grub.cfg`, then reboot.

## Why it's broken

- The laptop screen (`eDP-1`) runs on the Intel `xe` GPU, not the NVIDIA one.
- The driver controls brightness over PWM by default. This panel ignores PWM. It only listens to **DPCD** (commands sent over the DisplayPort AUX channel).
- So brightness writes succeed but nothing happens on the screen.
- `xe.enable_dpcd_backlight=1` switches the driver to DPCD.
- Ignore the `nvidia_0` backlight device. It belongs to a disconnected output.

| Value | Meaning |
|-------|---------|
| `-1` | Use VBT setting (broken default) |
| `0` | Disabled |
| `1` | DPCD, auto-pick interface (**works here**) |
| `2` | Force VESA DPCD |
| `3` | Force Intel DPCD |

## Tested on

| Part | Spec |
|------|------|
| Laptop | Lenovo Yoga Pro 7 15IPH11 (Yoga 7i Pro), machine type `83SN` |
| BIOS | `TNCN37WW` |
| CPU | Intel Core Ultra 7 356H (Panther Lake, 16 threads) |
| iGPU | Intel Panther Lake Graphics (`xe` driver), drives the screen |
| dGPU | NVIDIA GeForce RTX 5050 Max-Q / Mobile (GB207M) |
| RAM | 32 GB |
| Screen | 15" 2560x1600 16:10, 48-165 Hz, EDO `EF25QBA63.B` |
| OS | CachyOS, limine bootloader |
| Kernels | `6.18.35-1-cachyos-lts`, `7.3.0-4-cachyos` |
| Desktop | niri (Wayland) + noctalia-shell (`brightnessctl -d intel_backlight`) |

With the fix active, `max_brightness` reads `512`.
