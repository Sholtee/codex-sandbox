#!/bin/sh
# Open sign-in links inside the virtual desktop so callbacks reach the app there.
# Use Docker's isolation, software rendering, and a password store without a keyring.
# exec preserves process signals/exit status; "$@" preserves each URL argument.
exec chromium --no-sandbox --disable-gpu --password-store=basic "$@"
