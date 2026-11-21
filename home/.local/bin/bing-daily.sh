#!/bin/bash

# Wait for swww-daemon to be ready
sleep 2

if command -v awww >/dev/null 2>&1; then
    WALLPAPER_CLI="awww"
elif command -v swww >/dev/null 2>&1; then
    WALLPAPER_CLI="swww"
else
    echo "No wallpaper CLI found (awww/swww missing)" >> /tmp/bing-wallpaper.log
    exit 1
fi

# Download directory
WALLPAPER_DIR="$HOME/Pictures/BingDaily"
mkdir -p "$WALLPAPER_DIR"

# Delete wallpapers older than 7 days
find "$WALLPAPER_DIR" -name "bing-*.jpg" -type f -mtime +7 -delete

# Get Bing image URL
IMAGE_URL=$(curl -s "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US" | grep -oP '"url":"\K[^"]+')

if [ -z "$IMAGE_URL" ]; then
    echo "Failed to get Bing URL" >> /tmp/bing-wallpaper.log
    exit 1
fi

# Full URL
FULL_URL="https://www.bing.com${IMAGE_URL}"

# Download image
FILENAME="$WALLPAPER_DIR/bing-$(date +%Y-%m-%d).jpg"
curl -s -o "$FILENAME" "$FULL_URL"

# Stable path for hyprlock
[ -f "$FILENAME" ] && ln -sfn "$FILENAME" "$WALLPAPER_DIR/current.jpg"

# Set wallpaper with swww
if [ -f "$FILENAME" ]; then
    if "$WALLPAPER_CLI" img "$FILENAME" --transition-type fade --transition-duration 2; then
        echo "Wallpaper set with $WALLPAPER_CLI: $FILENAME" >> /tmp/bing-wallpaper.log
        # recolour the bar from the new wallpaper (Waybar reloads its CSS by itself)
        if command -v matugen >/dev/null 2>&1; then
            matugen image "$FILENAME" -m dark --prefer saturation -q >> /tmp/bing-wallpaper.log 2>&1
        fi
    else
        echo "Failed to apply wallpaper with $WALLPAPER_CLI: $FILENAME" >> /tmp/bing-wallpaper.log
        exit 1
    fi
else
    echo "Download failed" >> /tmp/bing-wallpaper.log
    exit 1
fi
