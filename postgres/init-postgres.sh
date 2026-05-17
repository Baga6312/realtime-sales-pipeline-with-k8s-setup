#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    SELECT 'CREATE DATABASE wordpress' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'wordpress')\gexec
    GRANT ALL PRIVILEGES ON DATABASE wordpress TO hiveuser;
    \c wordpress
    GRANT ALL ON SCHEMA public TO hiveuser;
EOSQL