#!/bin/bash

mkdir -p storage/primary
cp secrets/solace_withkey.pem storage/primary/solace_withkey.pem
cp secrets/passphrase.txt storage/primary/passphrase.txt
podman unshare chown 1000:1000 -R storage/primary

mkdir storage/backup
cp secrets/solace_withkey.pem storage/backup/solace_withkey.pem
cp secrets/passphrase.txt storage/backup/passphrase.txt
podman unshare chown 1000:1000 -R storage/backup

mkdir storage/monitor
cp secrets/solace_withkey.pem storage/monitor/solace_withkey.pem
cp secrets/passphrase.txt storage/monitor/passphrase.txt
podman unshare chown 1000:1000 -R storage/monitor

podman-compose -f solace_ha-podman-compose.yaml up
