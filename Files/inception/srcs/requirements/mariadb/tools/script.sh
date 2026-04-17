#!/bin/bash

set -e

# Initialize mysql datadir if empty
mkdir -p /var/lib/mysql
chown -R mysql:mysql /var/lib/mysql
chmod 777 /run/mysqld 2>/dev/null || mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# Start mysqld in background with --skip-networking so we can init DB
mysqld --skip-networking &
MYSQL_PID=$!
sleep 3

echo "CREATE DATABASE IF NOT EXISTS $db1_name ;" > db1.sql
echo "CREATE USER IF NOT EXISTS '$db1_user'@'%' IDENTIFIED BY '$db1_pwd' ;" >> db1.sql
echo "GRANT ALL PRIVILEGES ON $db1_name.* TO '$db1_user'@'%' ;" >> db1.sql

echo "FLUSH PRIVILEGES;" >> db1.sql

mysql < db1.sql

# Stop the background mysqld and start it in foreground mode
kill $MYSQL_PID 2>/dev/null || true
sleep 1

# Start mysqld in foreground (this is the main container process)
exec mysqld