# solace-ha-podman-compose
Configure a High-Availability group using Podman Compose in rootless mode.

## Getting started
### Create a Linux user to run the containers (optional)
First, create the group:
```
sudo groupadd -g 1000 solace
```

Next, create the user and add it to the group:
```
sudo useradd solace -u 1000 -g 1000 -m -s /bin/bash
```

Reset the password:
```
sudo passwd solace
```

Verify:
```
less /etc/passwd
solace:x:1000:1000::/home/solace:/bin/bash
```

### Update the user's limits
Reference: [Resource Limit Configuration](https://docs.solace.com/Software-Broker/Container-Tasks/rootless-containers.htm#Resource_Limit_Configuration)
```
sudo vi /etc/security/limits.conf 
solace     soft        core                 unlimited
solace     soft        memlock              unlimited
solace     soft        nofile               2448
solace     hard        nofile               42192
```

Reboot and verify the soft limits:
```
[solace@localhost ~]$ su - solace -c "ulimit -Sa"
Password: 
real-time non-blocking time  (microseconds, -R) unlimited
core file size              (blocks, -c) unlimited
data seg size               (kbytes, -d) unlimited
scheduling priority                 (-e) 0
file size                   (blocks, -f) unlimited
pending signals                     (-i) 14023
max locked memory           (kbytes, -l) 64
max memory size             (kbytes, -m) unlimited
open files                          (-n) 2448
pipe size                (512 bytes, -p) 8
POSIX message queues         (bytes, -q) 819200
real-time priority                  (-r) 0
stack size                  (kbytes, -s) 8192
cpu time                   (seconds, -t) unlimited
max user processes                  (-u) 14023
virtual memory              (kbytes, -v) unlimited
file locks                          (-x) unlimited
```
And the hard limits:
```
[solace@localhost ~]$ su - solace -c "ulimit -Ha"
Password: 
real-time non-blocking time  (microseconds, -R) unlimited
core file size              (blocks, -c) unlimited
data seg size               (kbytes, -d) unlimited
scheduling priority                 (-e) 0
file size                   (blocks, -f) unlimited
pending signals                     (-i) 14023
max locked memory           (kbytes, -l) 64
max memory size             (kbytes, -m) unlimited
open files                          (-n) 42192
pipe size                (512 bytes, -p) 8
POSIX message queues         (bytes, -q) 819200
real-time priority                  (-r) 0
stack size                  (kbytes, -s) unlimited
cpu time                   (seconds, -t) unlimited
max user processes                  (-u) 14023
virtual memory              (kbytes, -v) unlimited
file locks                          (-x) unlimited
```

### Generate a server certificate for the brokers
To enable TLS on the brokers you need TLS certificates. For test purpose only, [certificates](certificates) are available on this repo, you can use them or generate new ones.</br>
For example, to generate a self-signed certificate for the three nodes of the HA group:
```
SUBJECT='/CN=solaceprimary.solace.local/O=Solace/OU=PSG/L=Paris/ST=PARIS/C=FR'
SAN='DNS:solaceprimary.solace.local,DNS:solacebackup.solace.local,DNS:solacemonitor.solace.local'
openssl req \
    -new \
    -newkey rsa:4096 \
    -x509 \
    -subj "${SUBJECT}" \
    -addext "subjectAltName = ${SAN}" \
    -days 365 \
    -keyout solace.key \
    -out solace.pem \
    -passout pass:solace
```
Generate a file containing the server certificate and its private key:
```
cat solace.key solace.pem > solace_withkey.pem
```

#### Podman secrets
Optionally, you can store the passphrase and certificate files on a podman secret:
```
podman secret create passphrase.txt passphrase.txt
podman secret create solace_withkey.pem solace_withkey.pem
```

### Create and start the containers
```
chmod u+x create-podman.sh
./create-podman.sh
```

### Initialize config-sync
After starting the containers for the first time, you need to assert-leader the Message-VPNs because the newly configured brokers do not know which broker's configuration is to be synced.

Either with SEMP:
```
curl http://localhost:8080/SEMP -u admin:admin -d "<rpc><admin><config-sync><assert-leader><router/></assert-leader></config-sync></admin></rpc>"
curl http://localhost:8080/SEMP -u admin:admin -d "<rpc><admin><config-sync><assert-leader><vpn-name>default</vpn-name></assert-leader></config-sync></admin></rpc>"
curl http://localhost:8080/SEMP -u admin:admin -d "<rpc><admin><config-sync><assert-leader><vpn-name>solace</vpn-name></assert-leader></config-sync></admin></rpc>"
```

Or with CLI:
```
enable
admin
config-sync
assert-leader router
y
assert-leader message-vpn default
y
assert-leader message-vpn solace
y
```

### Remove the certificate files from the broker storage
Delete the certificate file + the file containing the passphrase:
```
sudo rm storage/primary/solace_withkey.pem
sudo rm storage/primary/passphrase.txt
sudo rm storage/backup/solace_withkey.pem
sudo rm storage/backup/passphrase.txt
sudo rm storage/monitor/solace_withkey.pem
sudo rm storage/monitor/passphrase.txt
```

### Manage the containers
Stop the containers:
```
podman-compose -f solace_ha-podman-compose.yaml stop
```

Remove the containers:
```
podman-compose -f solace_ha-podman-compose.yaml rm
```

Start the containers:
```
podman-compose -f solace_ha-podman-compose.yaml start
```
## Documentation
[Solace Rootless Containers](https://docs.solace.com/Software-Broker/Container-Tasks/rootless-containers.htm)
[Podman compose, an implementation of Compose Spec with Podman](https://github.com/containers/podman-compose)
[Exploring the Podman secret command](https://www.redhat.com/sysadmin/new-podman-secrets-command)

## Resources
This is not an officially supported Solace product.

For more information try these resources:
- Ask the [Solace Community](https://solace.community)
- The Solace Developer Portal website at: https://solace.dev

## Contributing
Contributions are encouraged! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors
See the list of [contributors](https://github.com/solacecommunity/solace-ha-podman-compose/graphs/contributors) who participated in this project.

## License
See the [LICENSE](LICENSE) file for details.