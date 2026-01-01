# FlexPrice Helm Chart - Testing & Validation Guide

This document provides comprehensive testing and validation procedures for all FlexPrice Helm chart use cases.

## Quick Start

Run all tests:

```bash
bash test-chart.sh
```

## Test Files

| File | Purpose |
|------|---------|
| `test-chart.sh` | Automated bash test suite (Linux/macOS) |
| `test-config.yaml` | Validation rules and test configuration |
| `USE_CASES.md` | Detailed use case documentation |

## Test Categories

### 1. Template Validation Tests

Verify that Helm templates render correctly without deployment:

```bash
# Test 1: Pre-Installed Operators
helm template flexprice . \
  --set postgres.operator.install=false \
  --set clickhouse.operator.install=false \
  --set kafka.operator.install=false \
  --set temporal.operator.install=false

# Test 2: External Services
helm template flexprice . -f examples/values-external.yaml

# Test 3: Operator Deployment
helm template flexprice . -f examples/values-operators.yaml

# Test 4: Minimal Development
helm template flexprice . -f examples/values-minimal.yaml
```

**Expected Results:**

| Test | Min Lines | Max Lines | Resources |
|------|-----------|-----------|-----------|
| Test 1 | 1200 | 1500 | No operator CRDs |
| Test 2 | 1200 | 1500 | No operator CRDs |
| Test 3 | 10000 | 12000 | All operator CRDs |
| Test 4 | 1200 | 1500 | Minimal operators |

### 2. Chart Linting

Validate chart structure and standards:

```bash
helm lint ./helm/flexprice
```

Expected output:
```
1 chart(s) linted, 0 chart(s) failed
```

### 3. Dependency Validation

Verify all chart dependencies are available:

```bash
helm dependency list ./helm/flexprice
```

Expected dependencies:
- stackgres-operator (1.18.3)
- altinity-clickhouse-operator (0.25.6)
- operator (25.3.1) - Redpanda
- temporal (0.44.0)

### 4. Dry Run Tests

Test actual Kubernetes deployment without creating resources:

```bash
# Test with default values
helm install flexprice ./helm/flexprice \
  --dry-run \
  --debug

# Test with external services
helm install flexprice ./helm/flexprice \
  -f examples/values-external.yaml \
  --dry-run \
  --debug

# Test with operators
helm install flexprice ./helm/flexprice \
  -f examples/values-operators.yaml \
  --dry-run \
  --debug
```

### 5. Resource Validation

Verify expected Kubernetes resources are generated:

```bash
# Count deployments
helm template flexprice . | grep "kind: Deployment" | wc -l
# Expected: 3 (api, consumer, worker)

# Count services
helm template flexprice . | grep "kind: Service" | wc -l
# Expected: 1+

# Count secrets
helm template flexprice . | grep "kind: Secret" | wc -l
# Expected: 2+

# Count configmaps
helm template flexprice . | grep "kind: ConfigMap" | wc -l
# Expected: 2+
```

### 6. Configuration Validation

Verify configuration values are correctly applied:

```bash
# Check API replicas in template
helm template flexprice . \
  --set flexprice.replicas.api=5 | \
  grep -A5 "name: flexprice-api" | \
  grep "replicas:"

# Check storage size in operator config
helm template flexprice . -f examples/values-operators.yaml | \
  grep -i "storage" | head -5
```

### 7. Secret & Credential Tests

Validate secret configurations:

```bash
# Check secret generation for internal credentials
helm template flexprice . | \
  grep -A10 "kind: Secret"

# Check secret references in deployments
helm template flexprice . | \
  grep -i "secretKeyRef\|secretRef" | head -5
```

### 8. Mixed Configuration Tests

Test hybrid operator + external service scenarios:

```bash
# PostgreSQL External, Others Operator
helm template flexprice . \
  --set postgres.external.enabled=true \
  --set postgres.external.host="pg.example.com" \
  --set postgres.external.user="user" \
  --set postgres.external.password="pass" \
  --set postgres.operator.install=false \
  --set clickhouse.operator.install=true \
  --set kafka.operator.install=true

# Kafka External, Others Operator
helm template flexprice . \
  --set kafka.external.enabled=true \
  --set kafka.external.brokers="{broker1:9092,broker2:9092}" \
  --set kafka.operator.install=false \
  --set postgres.operator.install=true \
  --set clickhouse.operator.install=true \
  --set temporal.operator.install=true
```

## Automated Testing

### Bash Test Script

The `test-chart.sh` script automates all validation tests:

```bash
bash test-chart.sh
```

Output:
```
================================
FLEXPRICE HELM CHART VALIDATION SUITE
================================

Chart: flexprice
Directory: /path/to/helm/flexprice

→ Use Case 1: Pre-Installed Operators
✓ PASSED: Use Case 1: Pre-Installed Operators (1429 lines generated)

→ Use Case 2: External Services
✓ PASSED: Use Case 2: External Services (1345 lines generated)

→ Use Case 3: Operator Deployment
✓ PASSED: Use Case 3: Operator Deployment (11903 lines generated)

→ Use Case 4: Minimal Development
✓ PASSED: Use Case 4: Minimal Development (1380 lines generated)

[... additional tests ...]

================================
TEST SUMMARY
================================
Total Tests: 8
Passed: 8
Failed: 0

All tests passed!
```

### Windows PowerShell Test

For Windows environments:

```powershell
$tests = @(
  @{
    name = "Pre-Installed Operators"
    cmd = "helm template flexprice . --set postgres.operator.install=false --set clickhouse.operator.install=false --set kafka.operator.install=false --set temporal.operator.install=false"
  },
  @{
    name = "External Services"
    cmd = "helm template flexprice . -f examples/values-external.yaml"
  },
  @{
    name = "Operator Deployment"
    cmd = "helm template flexprice . -f examples/values-operators.yaml"
  },
  @{
    name = "Minimal Development"
    cmd = "helm template flexprice . -f examples/values-minimal.yaml"
  }
)

$passed = 0
$failed = 0

foreach ($test in $tests) {
  Write-Host "Testing: $($test.name)" -ForegroundColor Yellow
  
  $output = Invoke-Expression $test.cmd 2>&1
  
  if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ PASSED" -ForegroundColor Green
    $passed++
  } else {
    Write-Host "✗ FAILED" -ForegroundColor Red
    $failed++
  }
}

Write-Host ""
Write-Host "Summary: $passed passed, $failed failed" -ForegroundColor Cyan
```

## Validation Checklist

### Pre-Deployment Validation

- [ ] Run `helm lint`
- [ ] Run `helm template` for your use case
- [ ] Verify template generates valid YAML
- [ ] Check dependencies with `helm dependency list`
- [ ] Validate with `helm install --dry-run`

### Template Validation

- [ ] Check for required resources (Deployments, Services, Secrets)
- [ ] Verify resource names are correct
- [ ] Check label selectors
- [ ] Verify environment variables
- [ ] Check volume mounts
- [ ] Validate resource limits/requests

### Configuration Validation

- [ ] Verify all external service addresses
- [ ] Check secret references
- [ ] Validate ConfigMap mount paths
- [ ] Check storage class names
- [ ] Verify image tags
- [ ] Check replica counts

### Deployment Validation

- [ ] Pods reach "Running" state
- [ ] Deployments show correct replica counts
- [ ] Services have endpoints
- [ ] No pending resources
- [ ] Logs show no errors
- [ ] Application is responsive

## Manual Testing Procedures

### Test External Services Configuration

```bash
# 1. Create namespace
kubectl create namespace flexprice

# 2. Create required secrets
kubectl create secret generic postgres-credentials \
  --from-literal=password='testpass' \
  -n flexprice

kubectl create secret generic clickhouse-credentials \
  --from-literal=password='testpass' \
  -n flexprice

# 3. Install with external values
helm install flexprice ./helm/flexprice \
  -f examples/values-external.yaml \
  -n flexprice

# 4. Monitor deployment
kubectl get pods -n flexprice -w

# 5. Check logs
kubectl logs -n flexprice deployment/flexprice-api

# 6. Verify connectivity
kubectl exec -it -n flexprice deployment/flexprice-api -- \
  curl http://localhost:8080/health
```

### Test Operator Deployment

```bash
# 1. Create namespace
kubectl create namespace flexprice

# 2. Install with operators
helm install flexprice ./helm/flexprice \
  -f examples/values-operators.yaml \
  -n flexprice

# 3. Monitor operator deployments
kubectl get pods -n flexprice -w

# 4. Check PostgreSQL cluster
kubectl get sgclusters -n flexprice

# 5. Check ClickHouse
kubectl get clickhouseinstallations -n flexprice

# 6. Check Redpanda
kubectl get redpandaclusters -n flexprice

# 7. Check Temporal
kubectl get deployment -n flexprice -l app.kubernetes.io/name=temporal

# 8. Wait for readiness
kubectl rollout status deployment/flexprice-api -n flexprice
```

### Test Minimal Development Setup

```bash
# 1. Start Temporal locally
docker run -d --name temporal -p 7233:7233 \
  temporalio/auto-setup:latest

# 2. Create namespace
kubectl create namespace flexprice

# 3. Install with minimal values
helm install flexprice ./helm/flexprice \
  -f examples/values-minimal.yaml \
  -n flexprice

# 4. Monitor pods
kubectl get pods -n flexprice

# 5. Port forward to access API
kubectl port-forward -n flexprice \
  svc/flexprice-api 8080:8080

# 6. Test API
curl http://localhost:8080/health
```

## Continuous Integration Testing

### GitHub Actions Example

```yaml
name: Helm Chart Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Helm
        uses: azure/setup-helm@v3
        with:
          version: 'latest'
      
      - name: Run Chart Validation
        run: |
          cd helm/flexprice
          helm lint .
          bash test-chart.sh
      
      - name: Template Test 1
        run: |
          cd helm/flexprice
          helm template flexprice . \
            --set postgres.operator.install=false \
            --set clickhouse.operator.install=false \
            --set kafka.operator.install=false \
            --set temporal.operator.install=false > /tmp/test1.yaml
          kubectl apply --dry-run=client -f /tmp/test1.yaml
      
      - name: Template Test 2
        run: |
          cd helm/flexprice
          helm template flexprice . -f examples/values-external.yaml > /tmp/test2.yaml
          kubectl apply --dry-run=client -f /tmp/test2.yaml
      
      - name: Template Test 3
        run: |
          cd helm/flexprice
          helm template flexprice . -f examples/values-operators.yaml > /tmp/test3.yaml
          kubectl apply --dry-run=client -f /tmp/test3.yaml
```

## Troubleshooting Test Failures

### Template Rendering Fails

**Error**: `Error: execution error at ... nil pointer`

**Solution**:
1. Check for duplicate keys in values.yaml
2. Verify all required fields are present
3. Use `helm template --debug` for more details
4. Review template conditions

### Lint Failures

**Error**: `[ERROR] ...`

**Solution**:
1. Check Chart.yaml format
2. Verify dependencies
3. Check YAML syntax
4. Run `helm dependency update`

### Dry-Run Deployment Fails

**Error**: `error validating ... for kind: ...`

**Solution**:
1. Verify Kubernetes version compatibility
2. Check resource API versions
3. Validate YAML syntax
4. Check resource limits

### Resource Count Mismatches

**Solution**:
1. Count expected resources manually
2. Check for conditional templates
3. Verify operator.install and external.enabled settings
4. Review template conditions in files

## Test Results Documentation

### Sample Test Results

```
HELM CHART VALIDATION TEST SUITE
================================

Chart: flexprice
Directory: ./helm/flexprice

Use Case 1: Pre-Installed Operators
✓ PASSED: 1429 lines generated
  - Deployments: 3 (api, consumer, worker)
  - Services: 1
  - Secrets: 2
  - ConfigMaps: 2
  - HPA: 1
  - PDB: 1
  - NetworkPolicy: 1

Use Case 2: External Services
✓ PASSED: 1345 lines generated
  - No operator CRDs
  - All external references configured
  - Secret placeholders present

Use Case 3: Operator Deployment
✓ PASSED: 11903 lines generated
  - SGCluster: 1
  - ClickHouseInstallation: 1
  - Redpanda: 1
  - Temporal: Deployments present
  - FlexPrice: All deployments present

Use Case 4: Minimal Development
✓ PASSED: 1380 lines generated
  - Minimal resource requests
  - 1 replica per deployment
  - Operator CRDs included

Dependencies: All required charts available
✓ PASSED

Chart Validation: Chart passes linting
✓ PASSED

TEST SUMMARY
Total Tests: 8
Passed: 8
Failed: 0

All tests passed!
```

## Maintenance

### Regular Testing Schedule

- [ ] Run tests on every code change
- [ ] Run tests on dependency updates
- [ ] Monthly full validation on real clusters
- [ ] Update tests when use cases change

### Updating Tests

When adding new features:

1. Create new use case in `USE_CASES.md`
2. Add new test in `test-chart.sh`
3. Add validation rules in `test-config.yaml`
4. Document in this file
5. Run full test suite
6. Commit all changes

## References

- [Helm Chart Testing Best Practices](https://helm.sh/docs/helm/helm_template/)
- [Kubernetes Testing Documentation](https://kubernetes.io/docs/)
- [FlexPrice Documentation](../README.md)
