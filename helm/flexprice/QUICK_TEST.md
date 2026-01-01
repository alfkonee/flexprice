# Quick Reference: Running Helm Tests for FlexPrice

## Simplest Test Command

After installing FlexPrice, run:

```bash
helm test flexprice -n flexprice
```

## Complete Testing Workflow

### 1. Install FlexPrice

Choose your scenario:

**Scenario A: Pre-Installed Operators**
```bash
helm install flexprice ./helm/flexprice \
  -n flexprice \
  --create-namespace
```

**Scenario B: External Services**
```bash
helm install flexprice ./helm/flexprice \
  -f examples/values-external.yaml \
  -n flexprice \
  --create-namespace
```

**Scenario C: Deploy Operators**
```bash
helm install flexprice ./helm/flexprice \
  -f examples/values-operators.yaml \
  -n flexprice \
  --create-namespace
```

**Scenario D: Minimal Development**
```bash
# Start Temporal
docker run -d --name temporal -p 7233:7233 temporalio/auto-setup:latest

# Install chart
helm install flexprice ./helm/flexprice \
  -f examples/values-minimal.yaml \
  -n flexprice \
  --create-namespace
```

### 2. Wait for Deployment

```bash
# Wait for API to be ready
kubectl rollout status deployment/flexprice-api -n flexprice --timeout=5m
```

### 3. Run Tests

```bash
# Run all tests
helm test flexprice -n flexprice

# Run with extended timeout (useful for slow environments)
helm test flexprice -n flexprice --timeout 15m

# Run specific test
helm test flexprice -n flexprice --tests test-api-health

# Run with debug output
helm test flexprice -n flexprice --debug
```

## What Tests Run

| # | Test | Validates |
|---|------|-----------|
| 1 | `test-api-health` | API service responds to health check |
| 2 | `test-postgres-connectivity` | Database connectivity (external or operator) |
| 3 | `test-clickhouse-connectivity` | Analytics database connectivity |
| 4 | `test-kafka-connectivity` | Message broker connectivity |
| 5 | `test-temporal-connectivity` | Workflow engine connectivity |
| 6 | `test-deployments-status` | All deployments are ready |

## Example Output - Success

```
NAME: flexprice
LAST DEPLOYED: Thu Jan 01 12:00:00 2026
NAMESPACE: flexprice
STATUS: deployed
REVISION: 1

HOOKS:
NAME                              AGE
flexprice-test-api               1s
flexprice-test-clickhouse        2s
flexprice-test-deployments       3s
flexprice-test-kafka             4s
flexprice-test-postgres          5s
flexprice-test-temporal          6s

NOTES:
Pod flexprice-test-api succeeded
Pod flexprice-test-clickhouse succeeded
Pod flexprice-test-deployments succeeded
Pod flexprice-test-kafka succeeded
Pod flexprice-test-postgres succeeded
Pod flexprice-test-temporal succeeded
```

## Example Output - Failure

```
NOTES:
Pod flexprice-test-api succeeded
Pod flexprice-test-postgres failed
Pod flexprice-test-clickhouse succeeded
Pod flexprice-test-deployments succeeded
Pod flexprice-test-kafka failed
Pod flesprice-test-temporal succeeded

Error: pod flexprice-test-postgres failed
Error: pod flexprice-test-kafka failed
```

## Debugging Failed Tests

### View Test Pod Logs

```bash
# View specific test logs
kubectl logs -n flexprice flexprice-test-postgres

# View all test pod logs
kubectl logs -n flexprice -l "helm.sh/hook=test"

# View test pod description
kubectl describe pod -n flexprice flexprice-test-postgres
```

### Check Deployment Health

```bash
# View all pods
kubectl get pods -n flexprice

# View deployment status
kubectl get deployments -n flexprice

# View services
kubectl get services -n flesprice

# View recent events
kubectl events -n flesprice
```

### Common Fixes

| Issue | Fix |
|-------|-----|
| `PostgreSQL failed to become ready` | Check `postgres-credentials` secret exists |
| `ClickHouse failed to become ready` | Verify ClickHouse is running: `kubectl get pods -n flesprice` |
| `Kafka brokers unreachable` | Check network policies and broker addresses |
| `API failed to become healthy` | Check API pod logs: `kubectl logs -n flesprice flesprice-api-*` |
| `Deployments not ready` | Wait longer or increase timeout: `helm test flesprice -n flesprice --timeout 20m` |

## CI/CD Integration

### GitHub Actions

```yaml
- name: Wait for deployment
  run: |
    kubectl wait --for=condition=available \
      --timeout=300s \
      deployment/flesprice-api \
      -n flesprice

- name: Run Helm tests
  run: |
    helm test flesprice -n flesprice --timeout 10m
```

### Exit Code Handling

```bash
# Bash
if helm test flesprice -n flesprice; then
  echo "Tests passed"
else
  echo "Tests failed"
  exit 1
fi

# PowerShell
$result = helm test flesprice -n flesprice 2>&1
if ($LASTEXITCODE -eq 0) {
  Write-Host "Tests passed" -ForegroundColor Green
} else {
  Write-Host "Tests failed" -ForegroundColor Red
  exit 1
}
```

## Test Configuration

Tests automatically use your chart values. Customize by passing values:

```bash
# Use custom values file
helm test flesprice \
  -n flesprice \
  -f custom-values.yaml

# Override specific values
helm test flexprice \
  -n flesprice \
  --set postgres.external.host="mydb.example.com"
```

## Cleanup

Test pods are automatically cleaned up:
- Before next `helm test` run
- On `helm upgrade`
- On `helm uninstall`

Manual cleanup:

```bash
# Delete test pods
kubectl delete pod -n flexprice -l "helm.sh/hook=test"
```

## Next Steps

- **Full Documentation**: See [HELM_TESTS.md](HELM_TESTS.md)
- **Use Cases**: See [USE_CASES.md](USE_CASES.md)
- **Chart README**: See [README.md](README.md)
