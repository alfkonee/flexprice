# FlexPrice Helm Chart - Helm Test Guide

This guide covers the built-in Helm tests for validating FlexPrice deployments.

## Quick Start

Run all tests after deployment:

```bash
helm test flexprice -n flexprice
```

## Tests Overview

The chart includes 6 comprehensive test pods that validate the deployment:

### 1. API Health Test
**Pod**: `flexprice-test-api`

Validates that the FlexPrice API service is running and responding to health checks.

```bash
# Run individually
helm test flexprice -n flexprice --tests test-api-health
```

**What it tests**:
- API service is accessible
- Health endpoint responds
- Pod is healthy and ready

**Example output**:
```
Pod flexprice-test-api succeeded
```

### 2. PostgreSQL Connectivity Test
**Pod**: `flexprice-test-postgres`

Validates database connectivity for both external and operator-managed PostgreSQL.

```bash
helm test flexprice -n flexprice --tests test-postgres-connectivity
```

**What it tests**:
- Database server is reachable
- Authentication credentials work
- Can execute SQL queries
- Works with both external and operator-managed databases

**Configuration**:
- External: Uses `postgres.external.*` settings
- Operator: Uses operator-deployed PostgreSQL
- Validates with `pg_isready` and actual connection test

### 3. ClickHouse Connectivity Test
**Pod**: `flexprice-test-clickhouse`

Validates analytics database connectivity.

```bash
helm test flexprice -n flexprice --tests test-clickhouse-connectivity
```

**What it tests**:
- ClickHouse server is reachable
- Authentication works
- Can execute queries
- Supports external and operator-managed instances

### 4. Kafka Connectivity Test
**Pod**: `flexprice-test-kafka`

Validates Kafka/Redpanda broker connectivity.

```bash
helm test flexprice -n flexprice --tests test-kafka-connectivity
```

**What it tests**:
- All brokers are reachable
- Broker ports are open
- Network connectivity works
- Supports multiple brokers

### 5. Temporal Connectivity Test
**Pod**: `flexprice-test-temporal`

Validates workflow orchestration platform connectivity.

```bash
helm test flexprice -n flexprice --tests test-temporal-connectivity
```

**What it tests**:
- Temporal frontend is reachable
- Network connectivity to Temporal
- Handles external Temporal instances

### 6. Deployments Status Test
**Pod**: `flexprice-test-deployments`

Validates that all FlexPrice deployments are ready.

```bash
helm test flexprice -n flexprice --tests test-deployments-status
```

**What it tests**:
- API deployment is ready
- Consumer deployment is ready
- Worker deployment is ready
- All pods are running

## Running Tests

### Run All Tests

```bash
helm test flexprice -n flexprice
```

**Output**:
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

### Run Specific Test

```bash
# Test only API
helm test flexprice -n flexprice --tests test-api-health

# Test only database connectivity
helm test flexprice -n flexprice --tests test-postgres-connectivity
```

### Run Tests with Timeout

```bash
# Default 5 minutes
helm test flexprice -n flexprice

# Custom timeout (10 minutes)
helm test flexprice -n flexprice --timeout 10m
```

### Run Tests in Debug Mode

```bash
helm test flexprice -n flexprice --debug
```

## Test Workflows

### Workflow 1: Pre-Installed Operators Scenario

```bash
# Install with operators pre-installed
helm install flexprice ./helm/flexprice \
  --set postgres.operator.install=false \
  --set clickhouse.operator.install=false \
  --set kafka.operator.install=false \
  --set temporal.operator.install=false \
  -n flexprice \
  --create-namespace

# Wait for deployment
kubectl rollout status deployment/flexprice-api -n flexprice

# Run tests
helm test flexprice -n flexprice
```

### Workflow 2: External Services Scenario

```bash
# Create namespace and secrets
kubectl create namespace flexprice
kubectl create secret generic postgres-credentials \
  --from-literal=password='your-password' \
  -n flexprice

# Install with external services
helm install flexprice ./helm/flexprice \
  -f examples/values-external.yaml \
  -n flexprice

# Run tests
helm test flexprice -n flexprice
```

### Workflow 3: Full Operator Deployment

```bash
# Install with all operators
helm install flexprice ./helm/flexprice \
  -f examples/values-operators.yaml \
  -n flexprice \
  --create-namespace

# Wait for operators to provision resources (this may take several minutes)
kubectl wait --for=condition=Ready pod \
  -l app.kubernetes.io/name=flexprice \
  -n flexprice \
  --timeout=600s

# Run tests
helm test flexprice -n flexprice
```

### Workflow 4: Minimal Development

```bash
# Start Temporal locally
docker run -d --name temporal -p 7233:7233 \
  temporalio/auto-setup:latest

# Install with minimal configuration
helm install flexprice ./helm/flexprice \
  -f examples/values-minimal.yaml \
  -n flexprice \
  --create-namespace

# Run tests
helm test flexprice -n flexprice
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Helm Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Helm
        uses: azure/setup-helm@v3
      
      - name: Set up Kind cluster
        uses: helm/kind-action@v1.7.0
      
      - name: Install chart dependencies
        run: |
          cd helm/flexprice
          helm dependency update
      
      - name: Template test
        run: |
          cd helm/flexprice
          helm template flexprice . \
            --set postgres.operator.install=false \
            --set clickhouse.operator.install=false \
            --set kafka.operator.install=false \
            --set temporal.operator.install=false
      
      - name: Install chart
        run: |
          helm install flexprice ./helm/flexprice \
            --set postgres.operator.install=false \
            --set clickhouse.operator.install=false \
            --set kafka.operator.install=false \
            --set temporal.operator.install=false \
            --namespace flexprice \
            --create-namespace
      
      - name: Wait for deployment
        run: |
          kubectl wait --for=condition=available \
            --timeout=300s \
            deployment/flexprice-api \
            -n flexprice
      
      - name: Run Helm tests
        run: |
          helm test flexprice \
            -n flexprice \
            --timeout 10m
```

### GitLab CI

```yaml
helm_test:
  image: alpine/helm:latest
  script:
    - helm dependency update ./helm/flexprice
    - helm template flexprice ./helm/flexprice
    - helm install flexprice ./helm/flexprice -n flexprice --create-namespace
    - helm test flexprice -n flexprice --timeout 10m
  artifacts:
    reports:
      junit: test-results.xml
```

## Test Configuration

### Customizing Test Behavior

Tests respect your values configuration:

```bash
# Run tests with custom values
helm test flexprice \
  -f custom-values.yaml \
  -n flexprice
```

### Environment-Specific Testing

```bash
# Development
helm test flexprice \
  -f examples/values-minimal.yaml \
  -n flexprice-dev

# Production
helm test flexprice \
  -f examples/values-operators.yaml \
  -n flexprice-prod

# Cloud/External
helm test flexprice \
  -f examples/values-external.yaml \
  -n flexprice-cloud
```

## Troubleshooting Tests

### Test Pod Debugging

View test pod logs:

```bash
# View API test logs
kubectl logs -n flexprice flexprice-test-api

# View all test pod logs
kubectl logs -n flexprice -l "helm.sh/hook=test"
```

### Common Issues

#### PostgreSQL Test Fails

**Symptoms**: `PostgreSQL failed to become ready`

**Solutions**:
1. Check PostgreSQL is running: `kubectl get pods -n flexprice | grep postgres`
2. Verify credentials: `kubectl get secret postgres-credentials -n flexprice`
3. Check logs: `kubectl logs -n flexprice flexprice-test-postgres`
4. For external: verify host/port/credentials in values

#### ClickHouse Test Fails

**Symptoms**: `ClickHouse failed to become ready`

**Solutions**:
1. Verify ClickHouse deployment: `kubectl get pods -n flexprice | grep clickhouse`
2. Check network connectivity: `kubectl exec -it <pod> -- nc -zv clickhouse-host 9000`
3. Verify credentials in secrets

#### Kafka Test Fails

**Symptoms**: `Failed to connect to broker`

**Solutions**:
1. Check Kafka/Redpanda pods: `kubectl get pods -n flexprice | grep kafka`
2. Verify broker addresses: `kubectl get svc -n flexprice`
3. Check network policies: `kubectl get networkpolicies -n flexprice`

#### API Test Fails

**Symptoms**: `API failed to become healthy`

**Solutions**:
1. Check API pod: `kubectl get pods -n flexprice flexprice-api-*`
2. View logs: `kubectl logs -n flexprice flexprice-api-*`
3. Test manually: `kubectl exec -it flexprice-api-* -- curl localhost:8080/health`

#### Deployment Test Fails

**Symptoms**: `deployment is not ready`

**Solutions**:
1. Check pod status: `kubectl get pods -n flexprice`
2. Describe pod: `kubectl describe pod -n flexprice <pod-name>`
3. Check resource usage: `kubectl top nodes`
4. View events: `kubectl events -n flexprice`

### Keeping Test Pods After Failure

By default, test pods are cleaned up. To keep them for debugging:

Edit `test-*.yaml` and remove the `helm.sh/hook-delete-policy` annotation:

```yaml
annotations:
  "helm.sh/hook": test
  # Remove or comment out:
  # "helm.sh/hook-delete-policy": before-this,failed
```

Then view failed pods:

```bash
kubectl get pods -n flexprice -l "helm.sh/hook=test"
kubectl logs -n flexprice <failed-pod-name>
```

## Test Cleanup

### Manual Cleanup

Remove test pods after testing:

```bash
# Delete all test pods
kubectl delete pod -n flexprice -l "helm.sh/hook=test"

# Or let the next test run clean them up automatically
```

### Automatic Cleanup

Tests are automatically cleaned up on:
- Next `helm test` run
- `helm upgrade`
- `helm uninstall`

## Advanced Testing

### Run Tests on Upgrade

```bash
# Install
helm install flexprice ./helm/flexprice -n flexprice

# Make changes to chart or values
vim helm/flexprice/values.yaml

# Upgrade and run tests
helm upgrade flexprice ./helm/flexprice \
  -n flexprice \
  --wait \
  && helm test flexprice -n flexprice
```

### Parallel Testing

Run tests in parallel (if your resources allow):

```bash
# Tests run sequentially by default
# To run in parallel, use a test orchestration tool or run multiple test commands:

helm test flexprice -n flexprice --tests test-api-health &
helm test flexprice -n flexprice --tests test-postgres-connectivity &
helm test flexprice -n flexprice --tests test-clickhouse-connectivity &
wait
```

## Test Reporting

### Capture Test Output

```bash
# Capture output to file
helm test flexprice -n flexprice > test-results.log 2>&1

# View results
cat test-results.log
```

### Parsing Test Results

```bash
# Check if all tests passed
if helm test flexprice -n flexprice; then
  echo "✓ All tests passed"
else
  echo "✗ Some tests failed"
  exit 1
fi
```

### Integration with Testing Tools

Tests can be integrated with:
- **Helm Operator**: Automatic testing on release
- **ArgoCD**: Pre/post-sync hooks
- **Flux**: Notification on test failure
- **Prometheus**: Alert on test failures

## Best Practices

1. **Run tests after every deployment**
   ```bash
   helm install flexprice ... && helm test flexprice -n flexprice
   ```

2. **Use consistent timeout values**
   ```bash
   helm test flexprice -n flexprice --timeout 10m
   ```

3. **Monitor test results in CI/CD**
   ```yaml
   - name: Run tests
     run: helm test flexprice -n flexprice
     continue-on-error: false
   ```

4. **Keep test pod logs for debugging**
   ```bash
   kubectl logs -n flexprice <test-pod> > test-logs.txt
   ```

5. **Test all use cases**
   - Pre-installed operators
   - External services
   - Operator deployment
   - Minimal development

6. **Update tests when adding features**
   - Add test pod template
   - Update this documentation
   - Include in CI/CD pipeline

## References

- [Helm Test Documentation](https://helm.sh/docs/helm/helm_test/)
- [Helm Hooks](https://helm.sh/docs/topics/charts_hooks/)
- [Kubernetes Pod Testing](https://kubernetes.io/docs/concepts/workloads/pods/)
- [FlexPrice USE_CASES.md](USE_CASES.md)
