#!/bin/bash

touch /root/create-database.sh

echo "#\!/usr/bin/env bash

mysql --user=root --password=\"\$MYSQL_ROOT_PASSWORD\" <<-EOSQL
    CREATE DATABASE IF NOT EXISTS ${mysql_database_name};
    GRANT ALL PRIVILEGES ON ${mysql_database_name}.* TO '\$MYSQL_USER'@'%';
EOSQL" | tee -a /root/create-database.sh

docker run --name mysql -d \
    -p 3306:3306 \
    -e MYSQL_ROOT_PASSWORD=${mysql_root_password} \
    -e MYSQL_USER=${mysql_user} \
    -e MYSQL_PASSWORD=${mysql_password} \
    -v mysql:/var/lib/mysql \
    -v /root/create-database.sh:/docker-entrypoint-initdb.d/create-database.sh \
    --restart unless-stopped \
    mysql/mysql-server:8.0

# connect mysql
# sudo docker exec -it mysql mysql -u root -p
