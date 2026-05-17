#!/bin/bash

# Run original WordPress entrypoint first
docker-entrypoint.sh apache2-foreground &
WP_PID=$!

# Wait for WordPress files
sleep 15

# Fix permissions
chown -R www-data:www-data /var/www/html/wp-content/

# Copy PG4WP
if [ ! -f /var/www/html/wp-content/db.php ]; then
    cp /tmp/postgresql-for-wordpress-3/pg4wp/db.php /var/www/html/wp-content/db.php
    mkdir -p /var/www/html/wp-content/plugins/pg4wp
    cp -r /tmp/postgresql-for-wordpress-3/pg4wp/* /var/www/html/wp-content/plugins/pg4wp/
fi

# Create logs directory
mkdir -p /var/www/html/wp-content/plugins/pg4wp/logs
chmod 777 /var/www/html/wp-content/plugins/pg4wp/logs

# Copy shop plugin
if [ ! -f /var/www/html/wp-content/plugins/shop-plugin.php ]; then
    cp /tmp/shop-plugin.php /var/www/html/wp-content/plugins/shop-plugin.php
fi

chown -R www-data:www-data /var/www/html/wp-content/

wait $WP_PID