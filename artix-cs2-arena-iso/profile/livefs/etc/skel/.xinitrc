#!/bin/sh
# .xinitrc — artix-cs2-arena live session
# Auto-start i3 on X init

if [ -d /etc/X11/xinit/xinitrc.d ]; then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh; do
        [ -x "$f" ] && . "$f"
    done
    unset f
fi

# Set keyboard layout
setxkbmap us

# Disable screen blanking in live session
xset s off
xset -dpms
xset s noblank

# Start i3
exec i3
