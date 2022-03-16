#!/bin/sh

TARGET_HOST=$1
SSH_USER=www-data

touch index.php

sftp -i /var/www/.ssh/id_ed25519 -oStrictHostKeyChecking=no -P36622 ${SSH_USER}@${TARGET_HOST}
 <<EOF
cd data
put index.php
quit
EOF