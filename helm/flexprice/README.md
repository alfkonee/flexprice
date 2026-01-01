# FlexPrice Helm Chart

This Helm chart deploys the FlexPrice backend with all its dependencies on Kubernetes.

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
   kubectl apply -f 'https://stackgres.io/install/latest/stackgres-operator.yaml'
   ```

2. **Altinity ClickHouse Operator**
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/Altinity/clickhouse-operator/master/deploy/operator/clickhouse-operator-install-bundle.yaml
   ```

3. **Redpanda Operator** (for Kafka-compatible messaging)
   ```bash
   helm repo add redpanda https://charts.redpanda.com
   helm install redpanda-operator redpanda/redpanda-operator
   ```

4. **Temporal**
   ```bash
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

## Production Recommendations

1. **Enable TLS** - Configure TLS for all external connections
2. **Use existing secrets** - Don't store credentials in values files
3. **Enable PodDisruptionBudget** - Set `flexprice.podDisruptionBudget.enabled: true`
4. **Configure resource limits** - Set appropriate CPU/memory limits
5. **Enable autoscaling** - Set `flexprice.autoscaling.enabled: true`
6. **Enable network policies** - Set `networkPolicy.enabled: true`
7. **Use read replicas** - Configure PostgreSQL reader endpoint for read-heavy workloads

## Upgrading

```bash
helm upgrade flexprice flexprice/flexprice -f my-values.yaml
```

## Uninstalling

```bash
helm uninstall flexprice
```

Note: This will not delete PersistentVolumeClaims created by the operators. To fully clean up:

```bash
kubectl delete pvc -l app.kubernetes.io/instance=flexprice
```

## Troubleshooting

### Check pod status
```bash
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

### Check migration job
```bash
kubectl get jobs -l app.kubernetes.io/instance=flexprice
kubectl logs job/flexprice-migrations
```

## License

This chart is licensed under the same license as FlexPrice. See [LICENSE](../../LICENSE) for details.
