# CI/CD Integration Guide

This guide shows how to integrate the FlexPrice Helm chart and its tests into your CI/CD pipeline.

## Quick Integration Examples

### GitHub Actions

```yaml
name: Deploy and Test FlexPrice

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  deploy-and-test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Helm
        uses: azure/setup-helm@v3
        with:
          version: 'v3.12.0'
      
      - name: Create KinD cluster
        uses: helm/kind-action@v1.7.0
        with:
          cluster_name: flexprice-test
          wait: 30s
      
      - name: Add Helm repositories
        run: |
          helm repo add stackgres-operator https://stackgres.io/downloads/stackgres-operator/helm
          helm repo add altinity https://charts.altinity.com/
          helm repo add redpanda https://charts.redpanda.com
          helm repo add temporal https://go.temporal.io/helm-charts
          helm repo update
      
      - name: Update chart dependencies
        run: |
          cd helm/flexprice
          helm dependency update
      
      - name: Install FlexPrice chart with operators
        run: |
          helm install flexprice helm/flexprice \
            -n flexprice \
            --create-namespace \
            -f helm/flexprice/examples/values-operators.yaml \
            --wait \
            --timeout 10m
      
      - name: Wait for deployments
        run: |
          kubectl wait --for=condition=available --timeout=5m \
            deployment/flexprice-api \
            deployment/flexprice-consumer \
            deployment/flexprice-worker \
            -n flexprice
      
      - name: Run Helm tests
        run: |
          helm test flexprice -n flexprice --timeout 5m
      
      - name: Collect test results
        if: always()
        run: |
          kubectl get pods -l helm.sh/hook=test -n flexprice -o wide
          kubectl logs -l helm.sh/hook=test -n flexprice --all-containers=true
      
      - name: Cleanup
        if: always()
        run: |
          helm uninstall flexprice -n flexprice || true
```

### GitLab CI

```yaml
stages:
  - test
  - deploy

variables:
  HELM_VERSION: "3.12.0"
  KUBE_VERSION: "1.27.0"

helm-template-test:
  stage: test
  image: alpine/helm:${HELM_VERSION}
  script:
    - cd helm/flexprice
    - helm repo add stackgres-operator https://stackgres.io/downloads/stackgres-operator/helm
    - helm repo add altinity https://charts.altinity.com/
    - helm repo add redpanda https://charts.redpanda.com
    - helm repo add temporal https://go.temporal.io/helm-charts
    - helm repo update
    - helm dependency update
    - helm template flexprice . -f examples/values-operators.yaml > /tmp/manifests-operators.yaml
    - helm template flexprice . -f examples/values-external.yaml > /tmp/manifests-external.yaml
    - helm template flexprice . -f examples/values-minimal.yaml > /tmp/manifests-minimal.yaml
    - echo "All templates validated successfully"
  artifacts:
    paths:
      - /tmp/manifests-*.yaml
    expire_in: 1 day

helm-deploy-test:
  stage: deploy
  image: ${CI_REGISTRY_IMAGE}:helm-${HELM_VERSION}
  script:
    - cd helm/flexprice
    - helm dependency update
    - helm install flexprice . -n flexprice --create-namespace -f examples/values-operators.yaml --wait --timeout 10m
    - kubectl wait --for=condition=available --timeout=5m deployment/flexprice-api -n flexprice
    - helm test flexprice -n flexprice --timeout 5m
    - helm uninstall flexprice -n flexprice
  only:
    - merge_requests
  environment:
    name: test-$CI_COMMIT_SHORT_SHA
    kubernetes_namespace: flexprice
```

### Jenkins Pipeline

```groovy
pipeline {
    agent any

    environment {
        HELM_VERSION = "3.12.0"
        CHART_PATH = "helm/flexprice"
        NAMESPACE = "flexprice"
    }

    stages {
        stage('Setup') {
            steps {
                script {
                    sh '''
                        helm repo add stackgres-operator https://stackgres.io/downloads/stackgres-operator/helm
                        helm repo add altinity https://charts.altinity.com/
                        helm repo add redpanda https://charts.redpanda.com
                        helm repo add temporal https://go.temporal.io/helm-charts
                        helm repo update
                    '''
                }
            }
        }

        stage('Validate Templates') {
            steps {
                script {
                    sh '''
                        cd ${CHART_PATH}
                        helm dependency update
                        
                        # Validate all example configurations
                        helm template flexprice . -f examples/values-operators.yaml > /dev/null
                        helm template flexprice . -f examples/values-external.yaml > /dev/null
                        helm template flexprice . -f examples/values-minimal.yaml > /dev/null
                        
                        echo "All templates validated successfully"
                    '''
                }
            }
        }

        stage('Deploy to Test Cluster') {
            steps {
                script {
                    sh '''
                        cd ${CHART_PATH}
                        
                        helm install flexprice . \
                            -n ${NAMESPACE} \
                            --create-namespace \
                            -f examples/values-operators.yaml \
                            --wait \
                            --timeout 10m
                    '''
                }
            }
        }

        stage('Run Tests') {
            steps {
                script {
                    sh '''
                        # Wait for deployments to be ready
                        kubectl wait --for=condition=available \
                            --timeout=5m \
                            deployment/flexprice-api \
                            deployment/flexprice-consumer \
                            deployment/flexprice-worker \
                            -n ${NAMESPACE}
                        
                        # Run Helm tests
                        helm test flexprice -n ${NAMESPACE} --timeout 5m
                    '''
                }
            }
        }

        stage('Collect Results') {
            when {
                always()
            }
            steps {
                script {
                    sh '''
                        mkdir -p test-results
                        
                        kubectl get pods -l helm.sh/hook=test -n ${NAMESPACE} -o wide \
                            > test-results/test-pods.txt
                        
                        kubectl logs -l helm.sh/hook=test -n ${NAMESPACE} \
                            --all-containers=true > test-results/test-logs.txt
                        
                        kubectl describe pods -l helm.sh/hook=test -n ${NAMESPACE} \
                            > test-results/test-descriptions.txt
                    '''
                }
            }
        }
    }

    post {
        always {
            script {
                sh '''
                    helm uninstall flexprice -n ${NAMESPACE} || true
                    kubectl delete ns ${NAMESPACE} || true
                '''
            }
            archiveArtifacts artifacts: 'test-results/**/*', allowEmptyArchive: true
        }
    }
}
```

## Pre-deployment Validation Checklist

Before deploying to production, run these validation steps:

```bash
#!/bin/bash
set -e

CHART_PATH="helm/flexprice"
VALUES_FILE="${1:-.}"

echo "📋 Starting pre-deployment validation..."

# 1. Validate chart structure
echo "✓ Validating chart structure..."
helm lint $CHART_PATH

# 2. Update dependencies
echo "✓ Updating chart dependencies..."
cd $CHART_PATH
helm dependency update

# 3. Validate all example configurations
echo "✓ Validating example configurations..."
for example in examples/values-*.yaml; do
    echo "  • Testing $example..."
    helm template flexprice . -f "$example" > /dev/null
done

# 4. Validate custom values file
if [ -n "$VALUES_FILE" ] && [ -f "$VALUES_FILE" ]; then
    echo "✓ Validating custom values file..."
    helm template flexprice . -f "$VALUES_FILE" > /dev/null
fi

# 5. Check for required fields
echo "✓ Checking required configuration fields..."
helm template flexprice . | kubectl apply --dry-run=client -f - > /dev/null

echo "✅ All validation checks passed!"
echo ""
echo "Ready to deploy with:"
echo "  helm install flexprice $CHART_PATH -f $VALUES_FILE"
```

## Production Deployment Pipeline

### Stage 1: Validation
1. Lint Helm chart
2. Template all configurations
3. Validate YAML syntax
4. Check for security issues (e.g., mounted secrets)

### Stage 2: Testing
1. Deploy to test environment
2. Run all Helm tests
3. Verify all deployments are ready
4. Check pod logs for errors
5. Test external connectivity (if applicable)

### Stage 3: Staging Deployment
1. Deploy to staging environment
2. Run full test suite
3. Performance validation
4. Load testing
5. Security scanning

### Stage 4: Production Deployment
1. Pre-deployment backup
2. Gradual rollout (canary deployment)
3. Health monitoring
4. Automated rollback on failure

## Monitoring After Deployment

```bash
#!/bin/bash

RELEASE="flexprice"
NAMESPACE="flexprice"

# Watch deployment rollout
kubectl rollout status deployment/$RELEASE-api -n $NAMESPACE --timeout=5m

# Monitor pod status
kubectl get pods -l app.kubernetes.io/instance=$RELEASE -n $NAMESPACE -w

# Check resource usage
kubectl top nodes
kubectl top pods -n $NAMESPACE

# Monitor logs
kubectl logs -l app.kubernetes.io/instance=$RELEASE -n $NAMESPACE --all-containers=true -f

# Verify operator status (if using operators)
kubectl get pods -l "app.kubernetes.io/name in (stackgres,clickhouse-operator,redpanda)" -n $NAMESPACE

# Check for issues
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -20
```

## Rollback Procedure

```bash
#!/bin/bash

RELEASE="flexprice"
NAMESPACE="flexprice"

# List previous releases
helm history $RELEASE -n $NAMESPACE

# Rollback to previous version
helm rollback $RELEASE 0 -n $NAMESPACE

# Verify rollback
helm status $RELEASE -n $NAMESPACE
kubectl get pods -l app.kubernetes.io/instance=$RELEASE -n $NAMESPACE
```

## Testing Specific Scenarios in CI/CD

### Test 1: Pre-installed Operators
```bash
helm install flexprice ./helm/flexprice \
  -n flexprice \
  --create-namespace \
  -f ./helm/flexprice/examples/values-operators.yaml \
  --wait --timeout 10m

# Tests expect operators already in place
helm test flexprice -n flexprice
```

### Test 2: External Services Only
```bash
helm install flexprice ./helm/flexprice \
  -n flexprice \
  --create-namespace \
  -f ./helm/flexprice/examples/values-external.yaml \
  --set postgres.external.host=$PG_HOST \
  --set postgres.external.user=$PG_USER \
  --set postgres.external.password=$PG_PASS \
  --wait --timeout 10m

helm test flexprice -n flexprice
```

### Test 3: Minimal Development Setup
```bash
helm install flexprice ./helm/flexprice \
  -n flexprice \
  --create-namespace \
  -f ./helm/flexprice/examples/values-minimal.yaml \
  --wait --timeout 10m

helm test flexprice -n flexprice
```

## Troubleshooting CI/CD Failures

### Test Pod Stuck in Pending
```bash
kubectl describe pod <test-pod-name> -n flexprice
# Check for resource constraints, node selectors, or image pull issues
```

### Service Not Accessible
```bash
kubectl get svc -n flexprice
kubectl port-forward svc/flexprice 8080:8080 -n flexprice
# Try to access from your machine
curl http://localhost:8080/health
```

### Database Connectivity Issues
```bash
# Check if external service is accessible
kubectl run -it --rm debug --image=postgres:15 --restart=Never -- \
  psql -h $PG_HOST -U $PG_USER -d $PG_DB

# Or for ClickHouse
kubectl run -it --rm debug --image=clickhouse/clickhouse-client --restart=Never -- \
  clickhouse-client -h $CH_HOST --user=$CH_USER --password=$CH_PASS
```

## Best Practices

1. **Always validate templates before deployment**
   ```bash
   helm template flexprice . | kubectl apply --dry-run=client -f -
   ```

2. **Use specific versions in CI/CD**
   ```bash
   helm install flexprice ./helm/flexprice --version 0.1.0
   ```

3. **Store secrets in CI/CD secrets manager, not in git**
   ```bash
   helm install flexprice ./helm/flexprice \
     --set postgres.external.password=$PG_PASSWORD \
     --set kafka.external.sasl.password=$KAFKA_PASSWORD
   ```

4. **Use namespaces to isolate environments**
   ```bash
   helm install flexprice ./helm/flexprice -n staging
   helm install flexprice ./helm/flexprice -n production
   ```

5. **Run tests against every deployment**
   ```bash
   helm test flexprice -n flexprice --timeout 5m
   ```

6. **Monitor test results and alert on failures**
   - Capture test pod logs in CI/CD artifacts
   - Set up alerts for failed test pods
   - Monitor application logs after tests pass

## See Also

- [QUICK_TEST.md](QUICK_TEST.md) - Quick reference for helm test commands
- [HELM_TESTS.md](HELM_TESTS.md) - Comprehensive testing guide
- [USE_CASES.md](USE_CASES.md) - Deployment scenarios with full configurations
