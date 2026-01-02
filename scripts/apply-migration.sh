#!/bin/bash
# Apply database migration

set -e

if [ -z "$1" ]; then
    echo "Error: Migration file not specified. Use './apply-migration.sh <path>'"
    exit 1
fi

MIGRATION_FILE="$1"

if [ ! -f "$MIGRATION_FILE" ]; then
    echo "Error: Migration file not found: $MIGRATION_FILE"
    exit 1
fi

echo "Applying migration file: $MIGRATION_FILE"

# Read config.yaml to get database connection details
if [ ! -f "config.yaml" ]; then
    echo "Error: config.yaml not found"
    exit 1
fi

# Parse YAML (simple parsing for postgres section)
HOST=$(grep -A 5 "postgres:" config.yaml | grep "host:" | awk '{print $2}')
USERNAME=$(grep -A 5 "postgres:" config.yaml | grep "username:" | awk '{print $2}')
PASSWORD=$(grep -A 5 "postgres:" config.yaml | grep "password:" | awk '{print $2}')
DATABASE=$(grep -A 5 "postgres:" config.yaml | grep "database:" | awk '{print $2}')

if [ -z "$HOST" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$DATABASE" ]; then
    echo "Error: Could not parse database configuration from config.yaml"
    exit 1
fi

echo "Connecting to PostgreSQL at $HOST..."
PGPASSWORD="$PASSWORD" psql -h "$HOST" -U "$USERNAME" -d "$DATABASE" -f "$MIGRATION_FILE"

if [ $? -eq 0 ]; then
    echo "Migration applied successfully"
else
    echo "Migration failed"
    exit 1
fi
