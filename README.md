# SFTP Container

Container for managing data over sftp server.

## Add user public key

There are two ways to setup public key

1. Set variable(s) SSH_CLIENT_someusername="ssh-ed25519 AAAAC3..." and /entrypoint will put it in user home authorized_keys for you
2. Mount authorized_keys directly to user home `/var/www/`

## Connect to sftp server

Container uses precreated user `www-data` with chrooted home under `/var/www/` directory. Directory is owned by root to be able to use ChrootDirectory sshd directive so you are not allowed to write anything directly in this directory.

See [`docker-compose.yaml`](./docker-compose.yaml) `sftp-test` service in case you struggle with connection.