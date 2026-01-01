# FlexPrice Helm Chart - Use Cases & Configuration Guide

This document codifies the various deployment scenarios and configurations supported by the FlexPrice Helm chart.

## Quick Navigation

- **[Use Case 1: Pre-Installed Operators](#use-case-1-pre-installed-operators)** - Operators already deployed in your cluster
- **[Use Case 2: External Services](#use-case-2-external-services)** - All dependencies running externally
- **[Use Case 3: Operator Deployment](#use-case-3-operator-deployment)** - Deploy all operators as chart dependencies
- **[Use Case 4: Minimal Development](#use-case-4-minimal-development)** - Lightweight development setup
- **[Use Case 5: Mixed Configuration](#use-case-5-mixed-configuration)** - Selectively use operators or external services
- **[Configuration Reference](#configuration-reference)** - Detailed settings for each component

---

## Use Case 1: Pre-Installed Operators

**Scenario**: Your cluster already has Stackgres, Altinity ClickHouse, Redpanda, and Temporal operators installed.

### When to Use
- Multi-tenant clusters where operators are shared
- Existing infrastructure with operators already deployed
- Team-managed operator installations
- Complex Kubernetes environments

### Configuration

#### Default Values
The chart defaults assume operators are pre-installed. Deploy with:

```bash
helm install flexprice ./helm/flexprice
```

Or explicitly:

```bash
helm install flexprice ./helm/flexprice \
  --set postgres.operator.install=false \
  --set clickhouse.operator.install=false \
  --set kafka.operator.install=false \
  --set temporal.operator.install=false
```

#### values.yaml Snippet
```yaml
postgres:
  operator:
    install: false      # Don't install operator chart
    enabled: true       # But use it if available

clickhouse:
  operator:
    install: false
    enabled: true

kafka:
  operator:
    install: false
    enabled: true

temporal:
  operator:
    install: false      # Use external Temporal or pre-deployed
    enabled: false
```

### Example Commands

```bash
# Deploy with default values (operators pre-installed)
helm install flexprice ./helm/flexprice \
  --namespace flexprice \
  --create-namespace

# Verify deployment
kubectl get pods -n flexprice
kubectl get deployment -n flexprice
```

### Validation Test
```bash
helm template flexprice . \
  --set postgres.operator.install=false \
  --set clickhouse.operator.install=false \
  --set kafka.operator.install=false \
  --set temporal.operator.install=false | wc -l
# Expected: ~1429 lines
```

---

## Use Case 2: External Services

**Scenario**: All database and messaging services are running externally (managed services, different cluster, Temporal Cloud).

### When to Use
- Cloud-managed databases (RDS, Cloud SQL, etc.)
- SaaS offerings (Temporal Cloud, managed ClickHouse)
- Multi-cluster deployments
- Simplified cluster management
- Development using local/Docker services

### Configuration

#### values-external.yaml
```yaml
flexprice:
  deploymentMode: "production"
  replicas:
    api: 3
    consumer: 3
    worker: 2

# External PostgreSQL
postgres:
  external:
    enabled: true
    host: "postgres.example.com"
    port: 5432
    user: "flexprice"
    database: "flexprice"
    existingSecret: "postgres-credentials"
    passwordKey: "password"
  operator:
    install: false
    enabled: false

# External ClickHouse
clickhouse:
  external:
    enabled: true
    address: "clickhouse.example.com:9000"
    user: "flexprice"
    existingSecret: "clickhouse-credentials"
    passwordKey: "password"
  operator:
    install: false
    enabled: false

# External Kafka
kafka:
  external:
    enabled: true
    brokers:
      - "kafka-0.example.com:9092"
      - "kafka-1.example.com:9092"
      - "kafka-2.example.com:9092"
    tls: true
    sasl:
      enabled: true
      mechanism: "SCRAM-SHA-512"
      existingSecret: "kafka-credentials"
  operator:
    install: false
    enabled: false

# External Temporal
temporal:
  external:
    enabled: true
    address: "temporal.example.com:7233"
    namespace: "flexprice"
    tls: true
    existingSecret: "temporal-credentials"
    apiKeySecretKey: "api-key"
  operator:
    install: false
    enabled: false
```

### Pre-requisites

Create secrets for external services:

```bash
# PostgreSQL credentials
kubectl create secret generic postgres-credentials \
  --from-literal=password='your-postgres-password' \
  -n flexprice

# ClickHouse credentials
kubectl create secret generic clickhouse-credentials \
  --from-literal=password='your-clickhouse-password' \
  -n flexprice

# Kafka credentials
kubectl create secret generic kafka-credentials \
  --from-literal=username='kafka-user' \
  --from-literal=password='kafka-password' \
  -n flexprice

# Temporal API key
kubectl create secret generic temporal-credentials \
  --from-literal=api-key='your-temporal-api-key' \
  -n flexprice
```

### Example Commands

```bash
# Deploy with external services
helm install flexprice ./helm/flexprice \
  -f examples/values-external.yaml \
  --namespace flexprice \
  --create-namespace

# Verify connectivity
kubectl logs -n flexprice deployment/flexprice-api -f | grep -i "connected\|error"
```

### Validation Test
```bash
helm template flexprice . -f examples/values-external.yaml | wc -l
# Expected: ~1345 lines
```

---

## Use Case 3: Operator Deployment

**Scenario**: Deploy FlexPrice with all operators as Helm chart dependencies. Fully self-contained setup.

### When to Use
- Standalone clusters
- Simplified operations (everything managed by Helm)
- Development/testing environments
- Complete infrastructure-as-code requirement
- Single-tenant deployments

### Configuration

#### values-operators.yaml
```yaml
flexprice:
  deploymentMode: "production"
  replicas:
    api: 2
    consumer: 2
    worker: 2

# PostgreSQL via Stackgres Operator
postgres:
  external:
    enabled: false
  operator:
    install: true      # Install operator chart
    enabled: true      # Deploy PostgreSQL cluster
    name: "flexprice-postgres"
    version: "17"
    instances: 3
    storage:
      size: "100Gi"
      storageClass: "fast-ssd"
    backup:
      enabled: true
      retention: 14
      schedule: "0 2 * * *"

# ClickHouse via Altinity Operator
clickhouse:
  external:
    enabled: false
  operator:
    install: true
    enabled: true
    name: "flexprice-clickhouse"
    version: "24.9"
    cluster:
      shardsCount: 2
      replicasCount: 2
    storage:
      size: "500Gi"
      storageClass: "fast-ssd"

# Redpanda via Redpanda Operator
kafka:
  external:
    enabled: false
  operator:
    install: true
    enabled: true
    name: "flexprice-redpanda"
    replicas: 3
    storage:
      size: "200Gi"
      storageClass: "fast-ssd"
    topics:
      - name: "events"
        partitions: 24
        replicationFactor: 3
      - name: "events_lazy"
        partitions: 12
        replicationFactor: 3

# Temporal via Helm Chart
temporal:
  external:
    enabled: false
  operator:
    install: true
    enabled: true
  # Database configuration for Temporal
  server:
    config:
      persistence:
        default:
          driver: "sql"
          sql:
            driver: "postgres12"
            host: "flexprice-postgres"
            port: 5432
            database: "temporal"
            user: "temporal"
            password: "generate-secure-password"
        visibility:
          driver: "sql"
          sql:
            driver: "postgres12"
            host: "flexprice-postgres"
            port: 5432
            database: "temporal_visibility"
            user: "temporal"
            password: "generate-secure-password"
```

### Prerequisites

Ensure your cluster has:
- Sufficient storage classes available
- CPU/Memory resources for operator deployments
- StatefulSet support

### Example Commands

```bash
# Deploy all operators
helm install flexprice ./helm/flexprice \
  -f examples/values-operators.yaml \
  --namespace flexprice \
  --create-namespace

# Monitor operator deployments
kubectl get pods -n flexprice -w

# Check PostgreSQL cluster
kubectl get sgclusters -n flexprice

# Check ClickHouse installation
kubectl get clickhouseinstallations -n flexprice

# Check Redpanda cluster
kubectl get redpandaclusters -n flexprice

# Check Temporal deployment
kubectl get deployment -n flexprice -l app.kubernetes.io/name=temporal
```

### Validation Test
```bash
helm template flexprice . -f examples/values-operators.yaml | wc -l
# Expected: ~11903 lines (includes all operator definitions)
```

---

## Use Case 4: Minimal Development

**Scenario**: Lightweight development setup with minimal resource requirements.

### When to Use
- Local development (with external Temporal)
- CI/CD test environments
- Developer laptops with Minikube/Docker Desktop
- Cost-conscious testing
- Rapid prototyping

### Configuration

#### values-minimal.yaml
```yaml
flexprice:
  image:
    tag: "latest"
  deploymentMode: "docker"
  replicas:
    api: 1
    consumer: 1
    worker: 1
  resources:
    requests:
      memory: "128Mi"
      cpu: "50m"
    limits:
      memory: "512Mi"
      cpu: "500m"
  service:
    type: NodePort

# PostgreSQL (minimal)
postgres:
  operator:
    install: true
    enabled: true
    instances: 1
    storage:
      size: "10Gi"
    backup:
      enabled: false

# ClickHouse (minimal)
clickhouse:
  operator:
    install: true
    enabled: true
    cluster:
      shardsCount: 1
      replicasCount: 1
    storage:
      size: "20Gi"

# Redpanda (minimal)
kafka:
  operator:
    install: true
    enabled: true
    replicas: 1
    storage:
      size: "20Gi"
  topics:
    - name: "events"
      partitions: 3
      replicationFactor: 1

# External Temporal (run locally)
temporal:
  external:
    enabled: true
    address: "temporal:7233"
    tls: false
  operator:
    install: false
    enabled: true
```

### Setup Instructions

```bash
# Option 1: Run Temporal in Docker
docker run -d \
  --name temporal \
  -p 7233:7233 \
  temporalio/auto-setup:latest

# Option 2: Run Temporal in Kubernetes (separate namespace)
helm repo add temporal https://go.temporal.io/helm-charts
helm install temporal temporal/temporal \
  -n temporal \
  --create-namespace

# Then deploy FlexPrice
helm install flexprice ./helm/flexprice \
  -f examples/values-minimal.yaml \
  --namespace flexprice \
  --create-namespace

# Port forward to access API
kubectl port-forward -n flexprice \
  svc/flexprice-api 8080:8080
```

### Validation Test
```bash
helm template flexprice . -f examples/values-minimal.yaml | wc -l
# Expected: ~1380 lines
```

---

## Use Case 5: Mixed Configuration

**Scenario**: Selectively use operators for some services, external for others.

### Example Combinations

#### PostgreSQL External + ClickHouse Operator
```bash
helm install flexprice ./helm/flexprice \
  --set postgres.external.enabled=true \
  --set postgres.external.host="rds-instance.rds.amazonaws.com" \
  --set postgres.external.user="flexprice" \
  --set postgres.external.password="secret" \
  --set postgres.operator.install=false \
  \
  --set clickhouse.operator.install=true \
  --set clickhouse.operator.enabled=true \
  \
  --set kafka.operator.install=true \
  --set kafka.operator.enabled=true \
  \
  --set temporal.external.enabled=true \
  --set temporal.external.address="temporal.example.com:7233"
```

#### Kafka External + Others Operator
```bash
helm install flexprice ./helm/flexprice \
  --set kafka.external.enabled=true \
  --set kafka.external.brokers="{broker1:9092,broker2:9092}" \
  --set kafka.operator.install=false \
  \
  --set postgres.operator.install=true \
  --set clickhouse.operator.install=true \
  --set temporal.operator.install=true
```

---

## Configuration Reference

### Global Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `flexprice.deploymentMode` | `production` | Deployment environment mode |
| `flexprice.image.tag` | `latest` | Container image version |
| `flexprice.replicas.api` | `2` | API server replicas |
| `flexprice.replicas.consumer` | `2` | Event consumer replicas |
| `flexprice.replicas.worker` | `2` | Background worker replicas |

### PostgreSQL Configuration

| Setting | Type | Description |
|---------|------|-------------|
| `postgres.external.enabled` | boolean | Use external PostgreSQL |
| `postgres.external.host` | string | Database hostname |
| `postgres.external.port` | number | Database port (default: 5432) |
| `postgres.external.user` | string | Database user |
| `postgres.external.password` | string | Database password |
| `postgres.operator.install` | boolean | Install Stackgres operator |
| `postgres.operator.enabled` | boolean | Deploy PostgreSQL cluster |
| `postgres.operator.instances` | number | PostgreSQL cluster size |
| `postgres.operator.storage.size` | string | Storage size (e.g., "100Gi") |

### ClickHouse Configuration

| Setting | Type | Description |
|---------|------|-------------|
| `clickhouse.external.enabled` | boolean | Use external ClickHouse |
| `clickhouse.external.address` | string | ClickHouse address (host:port) |
| `clickhouse.external.user` | string | ClickHouse user |
| `clickhouse.external.password` | string | ClickHouse password |
| `clickhouse.operator.install` | boolean | Install Altinity operator |
| `clickhouse.operator.enabled` | boolean | Deploy ClickHouse cluster |
| `clickhouse.operator.cluster.shardsCount` | number | Number of shards |
| `clickhouse.operator.cluster.replicasCount` | number | Replicas per shard |
| `clickhouse.operator.storage.size` | string | Storage size per node |

### Kafka Configuration

| Setting | Type | Description |
|---------|------|-------------|
| `kafka.external.enabled` | boolean | Use external Kafka/Redpanda |
| `kafka.external.brokers` | array | Broker addresses |
| `kafka.external.tls` | boolean | Enable TLS |
| `kafka.external.sasl.enabled` | boolean | Enable SASL authentication |
| `kafka.operator.install` | boolean | Install Redpanda operator |
| `kafka.operator.enabled` | boolean | Deploy Redpanda cluster |
| `kafka.operator.replicas` | number | Redpanda cluster size |
| `kafka.operator.storage.size` | string | Storage size per node |

### Temporal Configuration

| Setting | Type | Description |
|---------|------|-------------|
| `temporal.external.enabled` | boolean | Use external Temporal |
| `temporal.external.address` | string | Temporal frontend address |
| `temporal.external.namespace` | string | Workflow namespace |
| `temporal.external.tls` | boolean | Enable TLS |
| `temporal.operator.install` | boolean | Install Temporal chart |
| `temporal.operator.enabled` | boolean | Enable Temporal integration |
| `temporal.namespace` | string | Default workflow namespace |
| `temporal.taskQueue` | string | Default task queue name |

---

## Deployment Scenarios Matrix

| Scenario | PostgreSQL | ClickHouse | Kafka | Temporal | File |
|----------|------------|------------|-------|----------|------|
| Pre-Installed Operators | Operator | Operator | Operator | Operator | `values.yaml` (default) |
| External Services | External | External | External | External | `values-external.yaml` |
| All Operators | Operator | Operator | Operator | Operator | `values-operators.yaml` |
| Minimal Dev | Operator | Operator | Operator | External | `values-minimal.yaml` |
| Cloud-Native | External | External | External | External | Custom |
| Hybrid-1 | Operator | Operator | External | External | Custom |
| Hybrid-2 | External | Operator | Operator | External | Custom |

---

## Advanced Topics

### Secrets Management

All examples support three methods:

1. **Embedded Passwords** (development only)
   ```yaml
   postgres:
     password: "plain-text-password"  # NOT for production!
   ```

2. **Existing Secrets**
   ```yaml
   postgres:
     external:
       existingSecret: "postgres-credentials"
       passwordKey: "password"
   ```

3. **Generated Passwords** (operators)
   ```yaml
   postgres:
     password: ""  # Auto-generated
   ```

### Storage Classes

Customize storage for your infrastructure:

```yaml
postgres:
  operator:
    storage:
      storageClass: "fast-ssd"    # For production
      size: "100Gi"

clickhouse:
  operator:
    storage:
      storageClass: "standard"     # For cost-sensitive
      size: "20Gi"
```

### Resource Management

Adjust based on workload:

```yaml
postgres:
  operator:
    resources:
      requests:
        memory: "1Gi"
        cpu: "500m"
      limits:
        memory: "4Gi"
        cpu: "2000m"
```

### High Availability

For production deployments:

```yaml
postgres:
  operator:
    instances: 3          # 3-node cluster

clickhouse:
  operator:
    cluster:
      shardsCount: 2
      replicasCount: 2    # 2x replication

kafka:
  operator:
    replicas: 3           # 3-node cluster
```

---

## Validation & Testing

Run validation tests for each use case:

```bash
# Test 1: Pre-installed operators
helm template flexprice . \
  --set postgres.operator.install=false \
  --set clickhouse.operator.install=false \
  --set kafka.operator.install=false \
  --set temporal.operator.install=false

# Test 2: External services
helm template flexprice . -f examples/values-external.yaml

# Test 3: Operator deployment
helm template flexprice . -f examples/values-operators.yaml

# Test 4: Minimal development
helm template flexprice . -f examples/values-minimal.yaml

# Dry-run install
helm install --dry-run --debug flexprice ./helm/flexprice \
  -f your-values.yaml
```

---

## Troubleshooting

### Operators Not Found

If you see "operator not found" errors:

1. Verify operators are installed: `kubectl get crds | grep -i stackgres`
2. Check operator namespaces: `kubectl get pods --all-namespaces | grep -i operator`
3. Set `operator.install=true` to deploy operators as dependencies

### Database Connection Errors

For external services:

1. Verify connectivity: `kubectl run debug --image=curlimages/curl --rm -it -- sh`
2. Test from pod: `nc -zv hostname port`
3. Check secrets: `kubectl get secrets -n flexprice`
4. Verify credentials: `kubectl get secret postgres-credentials -o yaml`

### Resource Constraints

If pods are pending:

1. Check node resources: `kubectl top nodes`
2. Reduce resource requests in values
3. Use smaller storage sizes
4. Scale down replicas

---

## Next Steps

1. **Choose your use case** from the matrix above
2. **Use the corresponding values file** from `examples/`
3. **Customize settings** for your environment
4. **Validate with helm template** before installing
5. **Deploy**: `helm install flexprice ./helm/flexprice -f your-values.yaml`
6. **Monitor**: `kubectl get pods -n flexprice -w`

For more information, see [README.md](README.md) and individual example files.
