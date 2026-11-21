#!/bin/bash
# Refresh this repo from the live system, then review with `git status` / `git diff`.
# Only the lists below are copied. Secrets are deliberately NOT on any list (see README).
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
H="$REPO/home"
S="$REPO/system"
mkdir -p "$H/.config" "$H/.local/bin" "$S"

# ---- user config folders under ~/.config ----
CONFIG_DIRS="alacritty btop environment.d fish foot garuda gtk-3.0 gtk-4.0 htop hypr kanshi kitty Kvantum mako matugen micro mpv niri qt5ct qt6ct ranger swappy swaync Thunar touchegg waybar wlogout wofi wpaperd xsettingsd"
for d in $CONFIG_DIRS; do
  [ -d "$HOME/.config/$d" ] || continue
  rsync -a --delete --delete-excluded \
    --exclude='*.bak*' --exclude='bak-*' --exclude='*.log' --exclude='*cache*' --exclude='__pycache__' \
    --exclude='backups' --exclude='buffers' \
    "$HOME/.config/$d/" "$H/.config/$d/"
done

# ---- single files under ~/.config ----
for f in mimeapps.list user-dirs.dirs libinput-gestures.conf starship.toml; do
  [ -f "$HOME/.config/$f" ] && install -D -m 644 "$HOME/.config/$f" "$H/.config/$f"
done

# ---- dotfiles in $HOME (not .gitconfig.local, history, auth files, ssh) ----
for f in .zshrc .bashrc .bash_profile .profile .bashrc_cat .dircolors .gtkrc-2.0 .Xresources .gitconfig; do
  [ -f "$HOME/$f" ] && install -D -m 644 "$HOME/$f" "$H/$f"
done

# ---- own scripts ----
install -D -m 755 "$HOME/.local/bin/bing-daily.sh" "$H/.local/bin/bing-daily.sh"

# ---- system files (root-owned; applied manually with sudo, see README) ----
SYSTEM_FILES="
/etc/default/grub
/etc/default/grub-btrfs/config
/etc/sddm.conf
/etc/tlp.conf
/etc/tlp.d/10-battery.conf
/etc/tlp.d/20-fingerprint.conf
/etc/pam.d/sddm
/etc/pam.d/hyprlock
/etc/howdy/config.ini
/etc/systemd/system/sddm-bing.service
/etc/systemd/system/sddm-bing.timer
/etc/systemd/system/sddm-bing.service.d/grub.conf
/usr/local/bin/sddm-bing-update
/usr/local/bin/grub-bing-update
/usr/share/sddm/themes/Sweet6-bing/theme.conf
/usr/share/sddm/themes/Sweet6-bing/theme.conf.user
/usr/share/sddm/themes/Sweet6-bing/metadata.desktop
/usr/share/grub/themes/bing/theme.txt
"
for f in $SYSTEM_FILES; do
  [ -r "$f" ] && { mkdir -p "$S$(dirname "$f")"; cp -f "$f" "$S$f"; }
done

# ---- make it safe to publish: replace personal values with placeholders ----
[ -f "$H/.gitconfig" ] && sed -i 's/^\([[:space:]]*\)email = .*/\1email = you@example.com/; s/^\([[:space:]]*\)name = .*/\1name = Your Name/' "$H/.gitconfig"
[ -f "$S/etc/default/grub" ] && sed -i 's/resume=UUID=[0-9A-Fa-f-]*/resume=UUID=YOUR-SWAP-UUID/' "$S/etc/default/grub"

# ---- private blocklist: strings that must never appear (file is git-ignored, one regex per line) ----
if [ -f "$REPO/.private-patterns" ] && grep -rInEf "$REPO/.private-patterns" --exclude-dir=.git --exclude=sync.sh --exclude=.private-patterns "$REPO"; then
  echo "!! private string found above - sanitise it in sync.sh before committing" >&2
  exit 1
fi

# ---- safety net: refuse to leave obvious secrets in the repo ----
if grep -rIEn --exclude-dir=.git --exclude=sync.sh --exclude=README.md \
  'ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY-----' "$REPO"; then
  echo "!! possible secret found above - fix before committing" >&2
  exit 1
fi
echo "synced: $(find "$REPO" -path "$REPO/.git" -prune -o -type f -print | wc -l) files"
