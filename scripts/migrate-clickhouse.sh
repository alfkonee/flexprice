#!/bin/bash
# Run ClickHouse migrations

set -e

# Detect container runtime
if [ -z "$CONTAINER_RUNTIME" ]; then
    if command -v docker &> /dev/null && docker version &> /dev/null; then
        CONTAINER_RUNTIME="docker"
    elif command -v podman &> /dev/null && podman version &> /dev/null; then
        CONTAINER_RUNTIME="podman"
    else
        echo "Error: Neither docker nor podman found"
        exit 1
    fi
fi

COMPOSE="$CONTAINER_RUNTIME compose"

echo "Waiting for clickhouse to be ready..."
sleep 5

# Run all migration files
for file in migrations/clickhouse/*.sql; do
    if [ -f "$file" ]; then
        echo "Running migration: $file"
        $COMPOSE exec -T clickhouse clickhouse-client --user=flexprice --password=flexprice123 --database=flexprice --multiquery < "$file"
    fi
done

echo "Clickhouse migrations complete"
