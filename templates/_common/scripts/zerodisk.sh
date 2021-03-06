#!/bin/bash

# Zero out the free space to save space in the final image:
## ref: https://superuser.com/questions/1490371/error-writing-wipefile-no-space-left-on-device
sudo dd if=/dev/zero of=/EMPTY bs=1M
sudo rm -f /EMPTY

# Sync to ensure that the delete completes before this moves on.
sudo sync
sudo sync
sudo sync
