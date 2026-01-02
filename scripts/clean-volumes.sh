#!/bin/bash
# Clean Docker/Podman volumes

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

echo "Removing flexprice volumes using $CONTAINER_RUNTIME..."

# Get all volumes and filter for flexprice
volumes=$($CONTAINER_RUNTIME volume ls -q | grep flexprice || true)

if [ -n "$volumes" ]; then
    for volume in $volumes; do
        echo "Removing volume: $volume"
        $CONTAINER_RUNTIME volume rm "$volume" 2>/dev/null || true
    done
    echo "Volumes cleaned successfully"
else
    echo "No flexprice volumes found"
fi
