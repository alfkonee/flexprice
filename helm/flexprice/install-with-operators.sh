#!/bin/bash
# Two-step FlexPrice installation with operators
# This script ensures operators are deployed and CRDs are registered before creating cluster resources
#
# Usage:
#   ./install-with-operators.sh
#   ./install-with-operators.sh -v ./examples/values-operators-minimal.yaml
#   ./install-with-operators.sh -v ./examples/values-operators.yaml -n flexprice

set -euo pipefail

# Default values
VALUES_FILE="./examples/values-operators-minimal.yaml"
NAMESPACE="default"
RELEASE_NAME="flexprice"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Parse arguments
while getopts "v:n:r:h" opt; do
  case $opt in
    v) VALUES_FILE="$OPTARG" ;;
    n) NAMESPACE="$OPTARG" ;;
    r) RELEASE_NAME="$OPTARG" ;;
    h)
      echo "Usage: $0 [-v values_file] [-n namespace] [-r release_name]"
      echo "  -v  Values file (default: ./examples/values-operators-minimal.yaml)"
      echo "  -n  Namespace (default: default)"
      echo "  -r  Release name (default: flexprice)"
      exit 0
      ;;
    *)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}FlexPrice Two-Step Installation${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Step 1: Install only the operators (subcharts)
echo -e "${YELLOW}Step 1: Installing operators...${NC}"
echo -e "${GRAY}This will install Stackgres, ClickHouse, Redpanda, and Temporal operators${NC}"
echo ""

helm upgrade --install "$RELEASE_NAME" . \
    -f "$VALUES_FILE" \
    -n "$NAMESPACE" \
    --set postgres.operator.enabled=false \
    --set clickhouse.operator.enabled=false \
    --set kafka.operator.enabled=false \
    --wait --timeout 10m

echo -e "${GREEN}✓ Operators installed successfully${NC}"
echo ""

# Wait for CRDs to be registered
echo -e "${YELLOW}Step 2: Waiting for CRDs to be registered...${NC}"
echo -e "${GRAY}Checking for required CRDs...${NC}"

MAX_WAIT=120  # 2 minutes
WAITED=0
INTERVAL=5

REQUIRED_CRDS=(
    "sgclusters.stackgres.io"
    "clickhouseinstallations.clickhouse.altinity.com"
    "redpandas.cluster.redpanda.com"
)

while [ $WAITED -lt $MAX_WAIT ]; do
    ALL_READY=true
    
    for crd in "${REQUIRED_CRDS[@]}"; do
        if ! kubectl get crd "$crd" &>/dev/null; then
            ALL_READY=false
            echo -e "${GRAY}  Waiting for CRD: $crd${NC}"
            break
        fi
    done
    
    if [ "$ALL_READY" = true ]; then
        echo -e "${GREEN}✓ All CRDs are registered${NC}"
        break
    fi
    
    sleep $INTERVAL
    WAITED=$((WAITED + INTERVAL))
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo -e "${RED}✗ Timeout waiting for CRDs${NC}"
    echo -e "${YELLOW}Please check operator deployments and try again${NC}"
    exit 1
fi

echo ""

# Step 3: Install the complete chart including CRDs
echo -e "${YELLOW}Step 3: Creating database clusters...${NC}"
echo -e "${GRAY}This will create PostgreSQL, ClickHouse, and Redpanda clusters${NC}"
echo ""

helm upgrade --install "$RELEASE_NAME" . \
    -f "$VALUES_FILE" \
    -n "$NAMESPACE" \
    --wait --timeout 15m

echo -e "${GREEN}✓ Database clusters created successfully${NC}"
echo ""

echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "${GRAY}  1. Check pod status: kubectl get pods -n $NAMESPACE${NC}"
echo -e "${GRAY}  2. Run tests: helm test $RELEASE_NAME -n $NAMESPACE${NC}"
echo -e "${GRAY}  3. View logs: kubectl logs -l app.kubernetes.io/instance=$RELEASE_NAME -n $NAMESPACE${NC}"
echo ""
