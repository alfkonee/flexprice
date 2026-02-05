# FlexPrice Helm Chart

Production-ready Helm chart for deploying FlexPrice backend with flexible infrastructure options.

## Quick Start

```bash
# Add required Helm repositories
helm repo add stackgres https://stackgres.io/downloads/stackgres-k8s/stackgres/helm/
helm repo add altinity https://docs.altinity.com/clickhouse-operator/
helm repo add redpanda https://charts.redpanda.com
helm repo add temporal https://go.temporal.io/helm-charts
helm repo update

# Build chart dependencies
helm dependency build

# Test the chart (before installing)
./test-chart.sh              # Linux/macOS
.\test-chart.ps1             # Windows

# Install with all operators
helm install flexprice . \
  --set postgres.operator.install=true \
  --set clickhouse.operator.install=true \
  --set kafka.operator.install=true
```

```powershell
# Add required Helm repositories
helm repo add stackgres https://stackgres.io/downloads/stackgres-k8s/stackgres/helm/
helm repo add altinity https://docs.altinity.com/clickhouse-operator/
helm repo add redpanda https://charts.redpanda.com
helm repo add temporal https://go.temporal.io/helm-charts
helm repo update

# Build chart dependencies
helm dependency build

# Test the chart (before installing)
.\test-chart.ps1             # Windows

# Install with all operators
helm install flexprice . `
  --set postgres.operator.install=true `
  --set clickhouse.operator.install=true `
  --set kafka.operator.install=true
```

See [TESTING.md](TESTING.md) for complete testing guide and [USE_CASES.md](USE_CASES.md) for deployment scenarios.

## Prerequisites

This chart can optionally install the required operators as dependencies, or you can use pre-installed operators or external services.

### Option 1: Install Operators via This Chart

Set the `*.operator.install` options to `true` to have this chart install the operators:

```bash
helm install flexprice ./flexprice \
  --set postgres.operator.install=true \
  --set clickhouse.operator.install=true \
  --set kafka.operator.install=true \
  --set temporal.operator.install=true
```

### Option 2: Pre-install Operators Separately

If you prefer to manage operators separately:

1. **Stackgres Operator** (for PostgreSQL)
   ```bash
   helm install --create-namespace --namespace databases stackgres-operator --set-string adminui.service.type=ClusterIP https://stackgres.io/downloads/stackgres-k8s/stackgres/latest/helm/stackgres-operator.tgz
   ```
   ```powershell
   helm install --create-namespace --namespace databases stackgres-operator --set-string adminui.service.type=ClusterIP https://stackgres.io/downloads/stackgres-k8s/stackgres/latest/helm/stackgres-operator.tgz
   ```

2. **Altinity ClickHouse Operator**
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/Altinity/clickhouse-operator/master/deploy/operator/clickhouse-operator-install-bundle.yaml
   ```
   ```powershell
   kubectl apply -f https://raw.githubusercontent.com/Altinity/clickhouse-operator/master/deploy/operator/clickhouse-operator-install-bundle.yaml
   ```

3. **Redpanda Operator** (for Kafka-compatible messaging)
   ```bash
   helm repo add redpanda https://charts.redpanda.com
   helm install redpanda-operator redpanda/redpanda-operator
   ```
   ```powershell
   helm repo add redpanda https://charts.redpanda.com
   helm install redpanda-operator redpanda/redpanda-operator
   ```

4. **Temporal**
   ```bash
   helm repo add temporal https://go.temporal.io/helm-charts
   helm install temporal temporal/temporal
   ```
   ```powershell
   helm repo add temporal https://go.temporal.io/helm-charts
   helm install temporal temporal/temporal
   ```

Then install FlexPrice with operator CRDs enabled but install disabled:
```bash
helm install flexprice ./flexprice \
  --set postgres.operator.enabled=true \
  --set postgres.operator.install=false
```

### Option 3: Use External Services

Use your own existing services - see "Installation with External Services" below.

## Installation

### Basic Installation (Using Operators)

```bash
# Add the helm repo (if published)
helm repo add flexprice https://charts.flexprice.io

# Update dependencies (required before first install)
helm dependency update

# Install with operators managed by this chart
helm install flexprice flexprice/flexprice \
  --set postgres.operator.install=true \
  --set clickhouse.operator.install=true \
  --set kafka.operator.install=true \
  --set temporal.operator.install=true
```

```powershell
# Add the helm repo (if published)
helm repo add flexprice https://charts.flexprice.io

# Update dependencies (required before first install)
helm dependency update

# Install with operators managed by this chart
helm install flexprice flexprice/flexprice `
  --set postgres.operator.install=true `
  --set clickhouse.operator.install=true `
  --set kafka.operator.install=true `
  --set temporal.operator.install=true
```

### Installation with Pre-installed Operators

```bash
# Operators already installed in cluster, just create CRDs
helm install flexprice flexprice/flexprice
```

### Installation with External Services

If you already have the required services deployed in your cluster, you can use external connection strings:

```bash
helm install flexprice flexprice/flexprice \
  --set postgres.external.enabled=true \
  --set postgres.external.host=my-postgres.example.com \
  --set postgres.external.user=flexprice \
  --set postgres.external.password=mypassword \
  --set clickhouse.external.enabled=true \
  --set clickhouse.external.address=my-clickhouse.example.com:9000 \
  --set clickhouse.external.user=flexprice \
  --set clickhouse.external.password=mypassword \
  --set kafka.external.enabled=true \
  --set kafka.external.brokers[0]=my-kafka-1.example.com:9092 \
  --set kafka.external.brokers[1]=my-kafka-2.example.com:9092 \
  --set temporal.external.enabled=true \
  --set temporal.external.address=my-temporal.example.com:7233
```

### Using a Custom Values File

Create a `my-values.yaml` file:

```yaml
# Use external PostgreSQL
postgres:
  external:
    enabled: true
    host: "postgres.my-cluster.svc.cluster.local"
    port: 5432
    user: "flexprice"
    password: "secure-password"
    database: "flexprice"
    sslMode: "require"

# Use external ClickHouse
clickhouse:
  external:
    enabled: true
    address: "clickhouse.my-cluster.svc.cluster.local:9000"
    user: "flexprice"
    password: "secure-password"
    database: "flexprice"

# Use external Kafka
kafka:
  external:
    enabled: true
    brokers:
      - "kafka-0.my-cluster.svc.cluster.local:9092"
      - "kafka-1.my-cluster.svc.cluster.local:9092"
      - "kafka-2.my-cluster.svc.cluster.local:9092"
    sasl:
      enabled: true
      mechanism: "SCRAM-SHA-512"
      user: "flexprice"
      password: "secure-password"

# Use external Temporal
temporal:
  external:
    enabled: true
    address: "temporal.my-cluster.svc.cluster.local:7233"
    namespace: "default"

# Enable ingress
flexprice:
  ingress:
    enabled: true
    className: "nginx"
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
    hosts:
      - host: api.flexprice.example.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - secretName: flexprice-tls
        hosts:
          - api.flexprice.example.com
```

Install with custom values:

```bash
helm install flexprice flexprice/flexprice -f my-values.yaml
```

```powershell
helm install flexprice flexprice/flexprice -f my-values.yaml
```

## Deployment Scenarios

This section provides step-by-step deployment guides for common scenarios.

### Scenario 1: Complete Setup with Internal Operators (Recommended for Development)

Deploy everything with operators managed by Helm - PostgreSQL, ClickHouse, Redpanda, and Temporal all created by Kubernetes operators.

**Prerequisites:**
- Kubernetes cluster (1.20+)
- Helm 3.0+
- Internet access to download container images

**Steps:**

1. **Create namespace:**
   ```bash
   kubectl create namespace billing
   ```
   ```powershell
   kubectl create namespace billing
   ```

2. **Add Helm repositories:**
   ```bash
   helm repo add stackgres https://stackgres.io/downloads/stackgres-k8s/stackgres/helm/
   helm repo add altinity https://docs.altinity.com/clickhouse-operator/
   helm repo add redpanda https://charts.redpanda.com
   helm repo add temporal https://go.temporal.io/helm-charts
   helm repo update
   ```
   ```powershell
   helm repo add stackgres https://stackgres.io/downloads/stackgres-k8s/stackgres/helm/
   helm repo add altinity https://docs.altinity.com/clickhouse-operator/
   helm repo add redpanda https://charts.redpanda.com
   helm repo add temporal https://go.temporal.io/helm-charts
   helm repo update
   ```

3. **Build chart dependencies:**
   ```bash
   cd helm/flexprice
   helm dependency build
   ```
   ```powershell
   cd helm\flexprice
   helm dependency build
   ```

4. **Create values file** (`values-operators.yaml`):
   ```yaml
   postgres:
     operator:
       install: true
       enabled: true
       name: fprice-pg
       instances: 1
       version: "17"
       storage:
         size: "50Gi"
     password: "securepassword123"

   clickhouse:
     operator:
       install: true
       enabled: true
       cluster:
         name: fprice-ch
         shards: 1
         replicas: 1

   kafka:
     operator:
       install: true
       enabled: true
       cluster:
         name: fprice-rp
         brokers: 1

   temporal:
     external:
       enabled: true
       address: "fprice-pg:5432"  # Temporal uses same PostgreSQL
   ```

5. **Install FlexPrice chart:**
   ```bash
   helm install flexprice . \
     --namespace billing \
     --create-namespace \
     -f values-operators.yaml \
     --timeout 15m
   ```
   ```powershell
   helm install flexprice . `
     --namespace billing `
     --create-namespace `
     -f values-operators.yaml `
     --timeout 15m
   ```

6. **Deploy Temporal** (uses same Stackgres PostgreSQL):
   ```bash
   helm install temporal temporal/temporal \
     --namespace billing \
     -f examples/temporal-values-stackgres.yaml \
     --timeout 10m
   ```
   ```powershell
   helm install temporal temporal/temporal `
     --namespace billing `
     -f examples/temporal-values-stackgres.yaml `
     --timeout 10m
   ```

7. **Verify deployment:**
   ```bash
   kubectl get pods -n billing
   kubectl get svc -n billing
   ```
   ```powershell
   kubectl get pods -n billing
   kubectl get svc -n billing
   ```

**Expected Outcome:**
- All pods in Running state (1/1 for most, 2/2 for services with sidecars)
- PostgreSQL: `fprice-pg-0` (5/5)
- ClickHouse: `chi-fprice-ch-fprice-ch-0-0-0` (2/2)
- Redpanda: `fprice-rp-0` (2/2)
- Temporal: `temporal-frontend`, `temporal-history`, `temporal-matching`, `temporal-worker` (all 1/1)
- FlexPrice: `flexprice-api`, `flexprice-consumer`, `flexprice-worker` (all 1/1)

---

### Scenario 2: Operators Pre-installed, Using Operator CRDs Only

Deploy if operators are already installed in your cluster by other means.

**Prerequisites:**
- Stackgres, Altinity ClickHouse, Redpanda, and Temporal operators already installed
- Kubernetes cluster (1.20+)
- Helm 3.0+

**Steps:**

1. **Verify operators are running:**
   ```bash
   kubectl get deployments --all-namespaces | grep -E "stackgres|clickhouse|redpanda|temporal"
   ```
   ```powershell
   kubectl get deployments --all-namespaces | Select-String "stackgres|clickhouse|redpanda|temporal"
   ```

2. **Create values file** (`values-operators-only.yaml`):
   ```yaml
   postgres:
     operator:
       install: false  # Don't install operator
       enabled: true   # Create SGCluster CRD
       name: fprice-pg
       version: "17"

   clickhouse:
     operator:
       install: false
       enabled: true
       cluster:
         name: fprice-ch

   kafka:
     operator:
       install: false
       enabled: true
       cluster:
         name: fprice-rp

   temporal:
     external:
       enabled: true
       address: "temporal-frontend.temporal.svc.cluster.local:7233"
   ```

3. **Install FlexPrice:**
   ```bash
   helm install flexprice . \
     --namespace billing \
     --create-namespace \
     -f values-operators-only.yaml \
     --timeout 10m
   ```
   ```powershell
   helm install flexprice . `
     --namespace billing `
     --create-namespace `
     -f values-operators-only.yaml `
     --timeout 10m
   ```

4. **Deploy Temporal separately:**
   ```bash
   # Ensure Temporal is deployed in 'temporal' namespace
   helm install temporal temporal/temporal \
     --namespace temporal \
     --create-namespace \
     -f examples/temporal-values-stackgres.yaml
   ```
   ```powershell
   helm install temporal temporal/temporal `
     --namespace temporal `
     --create-namespace `
     -f examples/temporal-values-stackgres.yaml
   ```

5. **Verify:**
   ```bash
   kubectl get pods -n billing
   kubectl get sgclusters,chi,redpanda -n billing
   ```
   ```powershell
   kubectl get pods -n billing
   kubectl get sgclusters,chi,redpanda -n billing
   ```

---

### Scenario 3: Hybrid - Internal PostgreSQL/ClickHouse, External Redpanda and Temporal

Use Kubernetes operators for stateful services but point to existing Redpanda and Temporal clusters.

**Prerequisites:**
- Stackgres and Altinity ClickHouse operators installed
- External Redpanda cluster (e.g., managed service)
- External Temporal cluster (e.g., managed service)
- Kubernetes cluster (1.20+)
- Helm 3.0+

**Steps:**

1. **Create values file** (`values-hybrid.yaml`):
   ```yaml
   postgres:
     operator:
       install: false
       enabled: true
       name: fprice-pg
       version: "17"
       instances: 1

   clickhouse:
     operator:
       install: false
       enabled: true
       cluster:
         name: fprice-ch
         shards: 1

   # Use external Redpanda
   kafka:
     external:
       enabled: true
       brokers:
         - "redpanda-0.redpanda.example.com:9092"
         - "redpanda-1.redpanda.example.com:9092"
         - "redpanda-2.redpanda.example.com:9092"

   # Use external Temporal
   temporal:
     external:
       enabled: true
       address: "temporal-frontend.example.com:7233"
   ```

2. **Install FlexPrice:**
   ```bash
   helm install flexprice . \
     --namespace billing \
     --create-namespace \
     -f values-hybrid.yaml
   ```
   ```powershell
   helm install flexprice . `
     --namespace billing `
     --create-namespace `
     -f values-hybrid.yaml
   ```

3. **Verify:**
   ```bash
   kubectl get pods -n billing
   # Check logs to verify connectivity to external services
   kubectl logs -n billing deployment/flexprice-api
   ```
   ```powershell
   kubectl get pods -n billing
   kubectl logs -n billing deployment/flexprice-api
   ```

---

### Scenario 4: Full External Setup

Use completely external services - PostgreSQL, ClickHouse, Redpanda, and Temporal all managed outside Kubernetes.

**Prerequisites:**
- External PostgreSQL 13+ database
- External ClickHouse 21+ service
- External Redpanda cluster
- External Temporal server
- Kubernetes cluster (1.20+)
- Helm 3.0+

**Steps:**

1. **Create external databases:**
   ```sql
   -- On your external PostgreSQL
   CREATE DATABASE flexprice;
   CREATE DATABASE temporal;
   CREATE DATABASE temporal_visibility;
   
   -- On temporal_visibility database, enable btree_gin
   CREATE EXTENSION IF NOT EXISTS btree_gin;
   ```

2. **Create values file** (`values-external.yaml`):
   ```yaml
   postgres:
     external:
       enabled: true
       host: "postgres.example.com"
       port: 5432
       user: "flexprice"
       password: "secure-password"
       database: "flexprice"
       sslMode: "require"

   clickhouse:
     external:
       enabled: true
       address: "clickhouse.example.com:9000"
       user: "flexprice"
       password: "secure-password"
       database: "flexprice"

   kafka:
     external:
       enabled: true
       brokers:
         - "kafka-1.example.com:9092"
         - "kafka-2.example.com:9092"
         - "kafka-3.example.com:9092"

   temporal:
     external:
       enabled: true
       address: "temporal.example.com:7233"

   # Don't run migrations with external databases
   migrations:
     enabled: false
   ```

3. **Run migrations manually** (if needed):
   ```bash
   # Create FlexPrice tables
   flexprice-cli migrate up --database postgres://flexprice:password@postgres.example.com:5432/flexprice
   
   # Temporal schema is usually pre-configured
   ```

4. **Install FlexPrice:**
   ```bash
   helm install flexprice . \
     --namespace billing \
     --create-namespace \
     -f values-external.yaml
   ```
   ```powershell
   helm install flexprice . `
     --namespace billing `
     --create-namespace `
     -f values-external.yaml
   ```

5. **Verify:**
   ```bash
   kubectl get pods -n billing
   kubectl logs -n billing deployment/flexprice-api
   ```
   ```powershell
   kubectl get pods -n billing
   kubectl logs -n billing deployment/flexprice-api
   ```

---

## Key Configuration Files

| File | Purpose |
|------|---------|
| `examples/values-simple-operators.yaml` | Single-instance setup with all operators |
| `examples/values-operators.yaml` | Production setup with operators |
| `examples/values-external.yaml` | External services configuration |
| `examples/temporal-values-stackgres.yaml` | Temporal using Stackgres PostgreSQL |

```powershell
helm install flexprice flexprice/flexprice -f my-values.yaml
```

## Configuration

### Global Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.imagePullSecrets` | Image pull secrets for private registries | `[]` |
| `global.storageClass` | Storage class for persistent volumes | `""` |

### FlexPrice Application

| Parameter | Description | Default |
|-----------|-------------|---------|
| `flexprice.image.repository` | FlexPrice image repository | `flexprice/flexprice` |
| `flexprice.image.tag` | FlexPrice image tag | `latest` |
| `flexprice.deploymentMode` | Deployment mode (production/docker/local) | `production` |
| `flexprice.api.replicas` | Number of API replicas | `2` |
| `flexprice.consumer.replicas` | Number of consumer replicas | `2` |
| `flexprice.worker.replicas` | Number of worker replicas | `2` |

### PostgreSQL Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `postgres.external.enabled` | Use external PostgreSQL | `false` |
| `postgres.external.host` | External PostgreSQL host | `""` |
| `postgres.external.port` | External PostgreSQL port | `5432` |
| `postgres.external.user` | External PostgreSQL user | `""` |
| `postgres.external.password` | External PostgreSQL password | `""` |
| `postgres.external.existingSecret` | Use existing secret for credentials | `""` |
| `postgres.operator.install` | Install Stackgres operator via chart dependency | `false` |
| `postgres.operator.enabled` | Create Stackgres CRDs (SGCluster) | `true` |
| `postgres.operator.instances` | Number of PostgreSQL instances | `2` |
| `postgres.operator.storage.size` | Storage size for PostgreSQL | `50Gi` |

### ClickHouse Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `clickhouse.external.enabled` | Use external ClickHouse | `false` |
| `clickhouse.external.address` | External ClickHouse address (host:port) | `""` |
| `clickhouse.external.user` | External ClickHouse user | `""` |
| `clickhouse.external.password` | External ClickHouse password | `""` |
| `clickhouse.operator.install` | Install Altinity ClickHouse operator via chart dependency | `false` |
| `clickhouse.operator.enabled` | Create ClickHouse CRDs (ClickHouseInstallation) | `true` |
| `clickhouse.operator.cluster.shardsCount` | Number of shards | `1` |
| `clickhouse.operator.cluster.replicasCount` | Number of replicas per shard | `2` |

### Kafka/Redpanda Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `kafka.external.enabled` | Use external Kafka | `false` |
| `kafka.external.brokers` | List of external Kafka brokers | `[]` |
| `kafka.external.sasl.enabled` | Enable SASL authentication | `false` |
| `kafka.external.sasl.mechanism` | SASL mechanism | `""` |
| `kafka.operator.install` | Install Redpanda operator via chart dependency | `false` |
| `kafka.operator.enabled` | Create Redpanda CRDs (Redpanda cluster) | `true` |
| `kafka.operator.replicas` | Number of Redpanda brokers | `3` |

### Temporal Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `temporal.external.enabled` | Use external Temporal | `false` |
| `temporal.external.address` | External Temporal address | `""` |
| `temporal.external.namespace` | Temporal namespace | `default` |
| `temporal.operator.install` | Install Temporal via chart dependency | `false` |
| `temporal.operator.enabled` | Enable Temporal integration | `true` |

## Architecture

The FlexPrice backend consists of three main components:

1. **API Server** - Handles HTTP requests and API endpoints
2. **Consumer** - Processes events from Kafka/Redpanda
3. **Worker** - Executes background jobs via Temporal

### Dependencies

- **PostgreSQL** - Primary database for persistent storage
- **ClickHouse** - Analytics and event storage
- **Kafka/Redpanda** - Event streaming and messaging
- **Temporal** - Workflow orchestration and background jobs

## Using Existing Secrets

Instead of providing credentials directly in values, you can use existing Kubernetes secrets:

```yaml
postgres:
  external:
    enabled: true
    existingSecret: "my-postgres-secret"
    userKey: "username"
    passwordKey: "password"

clickhouse:
  external:
    enabled: true
    existingSecret: "my-clickhouse-secret"
    userKey: "username"
    passwordKey: "password"

kafka:
  external:
    enabled: true
    sasl:
      existingSecret: "my-kafka-secret"
      userKey: "username"
      passwordKey: "password"
```

## Testing

This chart includes comprehensive tests using Helm's native test feature. Tests validate connectivity to all dependencies and verify the deployment is healthy.

### Run All Tests

```bash
# Install the chart first
helm install flexprice ./flexprice -n flexprice

# Run all tests
helm test flexprice -n flexprice
```

```powershell
# Install the chart first
helm install flexprice ./flexprice -n flexprice

# Run all tests
helm test flexprice -n flexprice
```

### Run Specific Tests

```bash
# Test API health
helm test flexprice -n flexprice --tests test-api-health

# Test database connectivity
helm test flexprice -n flexprice --tests test-postgres-connectivity

# Test analytics database
helm test flexprice -n flexprice --tests test-clickhouse-connectivity

# Test message broker
helm test flexprice -n flexprice --tests test-kafka-connectivity

# Test workflow engine
helm test flexprice -n flexprice --tests test-temporal-connectivity

# Test deployment status
helm test flexprice -n flexprice --tests test-deployments-status
```

```powershell
# Test API health
helm test flexprice -n flexprice --tests test-api-health

# Test database connectivity
helm test flexprice -n flexprice --tests test-postgres-connectivity

# Test analytics database
helm test flexprice -n flexprice --tests test-clickhouse-connectivity

# Test message broker
helm test flexprice -n flexprice --tests test-kafka-connectivity

# Test workflow engine
helm test flexprice -n flexprice --tests test-temporal-connectivity

# Test deployment status
helm test flexprice -n flexprice --tests test-deployments-status
```

### View Test Results

```bash
# List all test pods
kubectl get pods -l app.kubernetes.io/instance=flexprice,helm.sh/hook=test

# View test output
kubectl logs test-pod-name -n flexprice

# Check test status
kubectl describe pod test-pod-name -n flexprice
```

```powershell
# List all test pods
kubectl get pods -l app.kubernetes.io/instance=flexprice,helm.sh/hook=test

# View test output
kubectl logs test-pod-name -n flexprice

# Check test status
kubectl describe pod test-pod-name -n flexprice
```

### Test Validation

Tests automatically detect your deployment configuration (external services vs operators) and validate accordingly:

- ✅ **test-api-health** - Verifies API responds to health checks on `/health` endpoint
- ✅ **test-postgres-connectivity** - Tests PostgreSQL connectivity (auto-detects external or operator-managed)
- ✅ **test-clickhouse-connectivity** - Verifies ClickHouse is accessible
- ✅ **test-kafka-connectivity** - Validates all Kafka brokers are reachable
- ✅ **test-temporal-connectivity** - Tests Temporal workflow engine connectivity
- ✅ **test-deployments-status** - Confirms all 3 deployments (api, consumer, worker) are ready

For detailed testing documentation, see [QUICK_TEST.md](QUICK_TEST.md) for quick reference or [HELM_TESTS.md](HELM_TESTS.md) for comprehensive guide.

## Documentation

- **[TESTING.md](TESTING.md)** - Complete testing guide (scripts, CI/CD, post-deployment tests)
- **[USE_CASES.md](USE_CASES.md)** - Detailed deployment scenarios and configurations

## Production Recommendations

1. **Enable TLS** - Configure TLS for all external connections
2. **Use existing secrets** - Don't store credentials in values files
3. **Enable PodDisruptionBudget** - Set `flexprice.podDisruptionBudget.enabled: true`
4. **Configure resource limits** - Set appropriate CPU/memory limits
5. **Enable autoscaling** - Set `flexprice.autoscaling.enabled: true`
6. **Enable network policies** - Set `networkPolicy.enabled: true`
7. **Use read replicas** - Configure PostgreSQL reader endpoint for read-heavy workloads
8. **Run tests regularly** - Use `helm test` in your CI/CD pipeline to validate deployments

## Upgrading

```bash
helm upgrade flexprice flexprice/flexprice -f my-values.yaml
```

```powershell
helm upgrade flexprice flexprice/flexprice -f my-values.yaml
```

## Uninstalling

```bash
helm uninstall flexprice
```

```powershell
helm uninstall flexprice
```

Note: This will not delete PersistentVolumeClaims created by the operators. To fully clean up:

```bash
kubectl delete pvc -l app.kubernetes.io/instance=flexprice
```

```powershell
kubectl delete pvc -l app.kubernetes.io/instance=flexprice
```

## Troubleshooting

### Check pod status
```bash
kubectl get pods -l app.kubernetes.io/instance=flexprice
```

```powershell
kubectl get pods -l app.kubernetes.io/instance=flexprice
```

### View logs
```bash
# API logs
kubectl logs -l app.kubernetes.io/instance=flexprice,app.kubernetes.io/component=api -f

# Consumer logs
kubectl logs -l app.kubernetes.io/instance=flexprice,app.kubernetes.io/component=consumer -f

# Worker logs
kubectl logs -l app.kubernetes.io/instance=flexprice,app.kubernetes.io/component=worker -f
```

```powershell
# API logs
kubectl logs -l app.kubernetes.io/instance=flexprice,app.kubernetes.io/component=api -f

# Consumer logs
kubectl logs -l app.kubernetes.io/instance=flexprice,app.kubernetes.io/component=consumer -f

# Worker logs
kubectl logs -l app.kubernetes.io/instance=flexprice,app.kubernetes.io/component=worker -f
```

### Check migration job
```bash
kubectl get jobs -l app.kubernetes.io/instance=flexprice
kubectl logs job/flexprice-migrations
```

```powershell
kubectl get jobs -l app.kubernetes.io/instance=flexprice
kubectl logs job/flexprice-migrations
```

## License

This chart is licensed under the same license as FlexPrice. See [LICENSE](../../LICENSE) for details.
