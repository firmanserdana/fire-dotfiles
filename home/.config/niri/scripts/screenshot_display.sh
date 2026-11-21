#!/bin/bash
# Screenshot the focused display and open it in swappy (Shift+Print)
output=$(niri msg -j focused-output | jq -r '.name')
grim -o "$output" - | swappy -f -
