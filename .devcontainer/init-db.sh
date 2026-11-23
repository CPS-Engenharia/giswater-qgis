#!/bin/bash
set -e

echo "=========================================="
echo "Initializing Giswater Database"
echo "=========================================="

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS postgis;
    CREATE EXTENSION IF NOT EXISTS postgis_topology;
    CREATE EXTENSION IF NOT EXISTS pgrouting;
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS "hstore";
    
    GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $POSTGRES_USER;
    
    SELECT version() AS postgresql_version;
    SELECT PostGIS_Full_Version();
    SELECT pgr_version() AS pgrouting_version;
EOSQL

echo "=========================================="
echo "Database initialization complete!"
echo "=========================================="
echo ""
echo "Database Info:"
echo "  PostgreSQL: 17"
echo "  PostGIS: 3.5"
echo "  pgRouting: 3.8"
echo "  Database: $POSTGRES_DB"
echo "  User: $POSTGRES_USER"
echo ""