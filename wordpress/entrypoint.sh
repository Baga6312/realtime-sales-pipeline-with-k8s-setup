#!/bin/bash

# Copy PG4WP files if not already there
if [ ! -f /var/www/html/wp-content/db.php ]; then
    cp /tmp/postgresql-for-wordpress-3/pg4wp/db.php /var/www/html/wp-content/db.php
    mkdir -p /var/www/html/wp-content/plugins/pg4wp
    cp -r /tmp/postgresql-for-wordpress-3/pg4wp/* /var/www/html/wp-content/plugins/pg4wp/
fi

# Run original WordPress entrypoint
docker-entrypoint.sh apache2-foreground