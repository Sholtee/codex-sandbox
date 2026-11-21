#!/bin/sh
# Replace this launcher with the app, preserving its PID, signals, and exit code.
# Docker provides isolation (--no-sandbox); rendering uses software and X11.
# The basic password store works without a keyring, so keep the home volume private.
# Forward arguments unchanged, including sign-in callback URLs.
exec chatgpt --no-sandbox --disable-gpu --ozone-platform=x11 --password-store=basic "$@"
