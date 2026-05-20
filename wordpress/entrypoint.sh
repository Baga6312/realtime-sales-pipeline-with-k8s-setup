#!/bin/bash

# Run original WordPress entrypoint in background
docker-entrypoint.sh apache2-foreground &
WP_PID=$!

# Wait for WordPress files to be fully copied
echo "Waiting for WordPress files..."
while [ ! -f /var/www/html/wp-includes/load.php ]; do
    sleep 2
done
echo "WordPress files ready!"

# Fix permissions
chown -R www-data:www-data /var/www/html/wp-content/

# Copy PG4WP
if [ ! -f /var/www/html/wp-content/db.php ]; then
    cp /tmp/postgresql-for-wordpress-3/pg4wp/db.php /var/www/html/wp-content/db.php
    mkdir -p /var/www/html/wp-content/plugins/pg4wp
    cp -r /tmp/postgresql-for-wordpress-3/pg4wp/* /var/www/html/wp-content/plugins/pg4wp/
    echo "PG4WP installed!"
fi

# Patch PG4WP information_schema bug
sed -i 's/throw new Exception/\/\/throw new Exception/' /var/www/html/wp-content/plugins/pg4wp/rewriters/SelectSQLRewriter.php

# Create logs directory
mkdir -p /var/www/html/wp-content/plugins/pg4wp/logs
chmod 777 /var/www/html/wp-content/plugins/pg4wp/logs

# Copy shop plugin
if [ ! -f /var/www/html/wp-content/plugins/shop-plugin.php ]; then
    cp /tmp/shop-plugin.php /var/www/html/wp-content/plugins/shop-plugin.php
fi

chown -R www-data:www-data /var/www/html/wp-content/

wait $WP_PID