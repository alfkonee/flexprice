# FlexPrice Helm Chart - Complete Package

## 📦 What You Have

A production-ready Helm chart for deploying the complete FlexPrice backend with:

- **FlexPrice Components**: API server, consumer, worker
- **Database Layer**: PostgreSQL (via Stackgres operator)
- **Analytics**: ClickHouse (via Altinity operator)
- **Messaging**: Kafka/Redpanda (via Redpanda operator)
- **Workflow Engine**: Temporal
- **Automatic Testing**: 6 Helm test pods validating all components

---

## 📂 Directory Structure

```
helm/flexprice/
├── Chart.yaml                    # Chart metadata & operator dependencies
├── values.yaml                   # Main values configuration
├── README.md                      # Overview & installation guide
│
├── 📖 DOCUMENTATION/
│   ├── QUICK_TEST.md             # ⏱️ 5-min quick start guide
│   ├── HELM_TESTS.md             # 📋 Comprehensive testing guide
│   ├── USE_CASES.md              # 5 deployment scenarios with configs
│   ├── TESTING.md                # Manual testing & troubleshooting
│   ├── CI_CD_INTEGRATION.md       # GitHub/GitLab/Jenkins integration
│   └── DOCUMENTATION_INDEX.md     # This file index (you are here)
│
├── 📋 CONFIGURATION/
│   ├── examples/
│   │   ├── values-operators.yaml     # All operators deployed via chart
│   │   ├── values-external.yaml      # All external services
│   │   └── values-minimal.yaml       # Minimal development setup
│   └── values.yaml                   # Default values
│
├── 🏗️ TEMPLATES/
│   ├── deployment-api.yaml           # API server deployment
│   ├── deployment-consumer.yaml      # Consumer deployment
│   ├── deployment-worker.yaml        # Worker deployment
│   │
│   ├── stackgres-cluster.yaml        # PostgreSQL operator CRD
│   ├── clickhouse-cluster.yaml       # ClickHouse operator CRD
│   ├── redpanda-cluster.yaml         # Redpanda operator CRD
│   │
│   ├── job-migrations.yaml           # Database migration job
│   ├── configmap.yaml                # Application configuration
│   ├── secret.yaml                   # Credentials management
│   │
│   ├── service.yaml                  # Kubernetes service
│   ├── ingress.yaml                  # Ingress configuration
│   ├── hpa.yaml                      # Horizontal pod autoscaler
│   ├── pdb.yaml                      # Pod disruption budget
│   ├── networkpolicy.yaml            # Network policies
│   │
│   ├── serviceaccount.yaml           # Service account
│   ├── configmap-rbac.yaml           # RBAC configuration
│   │
│   ├── _helpers.tpl                  # Template helpers
│   ├── _env.tpl                      # Environment variable generation
│   ├── NOTES.txt                     # Post-installation notes
│   │
│   └── tests/                        # 🧪 Helm test pods
│       ├── test-api-health.yaml
│       ├── test-postgres-connectivity.yaml
│       ├── test-clickhouse-connectivity.yaml
│       ├── test-kafka-connectivity.yaml
│       ├── test-temporal-connectivity.yaml
│       └── test-deployments-status.yaml
│
├── 🔧 UTILITIES/
│   ├── test-chart.sh                 # Bash test automation (legacy)
│   └── test-config.yaml              # Test configuration matrix (legacy)
│
└── 📊 CHART FILES/
    ├── Chart.lock                    # Dependency lock file
    └── charts/                       # Downloaded operator charts
        ├── stackgres-operator/
        ├── clickhouse-operator/
        ├── redpanda/ (operator)
        └── temporal/
```

---

## ✨ Key Features

### 🔀 Flexible Deployment Modes

1. **Pre-installed Operators** - Operators already in cluster, chart just creates CRDs
2. **External Services** - Use your own PostgreSQL, ClickHouse, Kafka, Temporal
3. **Operator Deployment** - Chart installs and manages all operators
4. **Minimal Development** - Lightweight setup for local development
5. **Mixed Configuration** - Some services from operators, some external

### 🧪 Comprehensive Testing

- 6 Helm test pods that automatically detect your configuration
- Tests validate API health, database connectivity, deployment readiness
- Works with all 5 deployment scenarios
- Run with: `helm test flexprice -n flexprice`

### 📦 Operator Dependencies

All operators managed through Helm:

| Operator | Chart | Version | Purpose |
|----------|-------|---------|---------|
| Stackgres | stackgres-operator | 1.18.3 | PostgreSQL 17 |
| Altinity ClickHouse | clickhouse-operator | 0.25.6 | ClickHouse Analytics DB |
| Redpanda | redpanda/operator | 25.3.1 | Kafka-compatible messaging |
| Temporal | temporal | 0.44.0 | Workflow orchestration |

### 🔒 Security Features

- Service accounts with minimal RBAC
- Network policies to restrict traffic
- Secret management for credentials
- Support for existing Kubernetes secrets
- TLS support for all connections

### 📊 Scalability

- Horizontal Pod Autoscaler configuration
- Pod Disruption Budgets for high availability
- Resource limits and requests
- Node affinity and pod affinity options

---

## 🚀 Quick Start (5 minutes)

### Prerequisites
```bash
# Helm 3.8+
helm --version

# kubectl access to cluster
kubectl cluster-info
```

### Basic Installation (All Operators)

```bash
# 1. Navigate to chart
cd helm/flexprice

# 2. Update dependencies
helm dependency update

# 3. Install chart
helm install flexprice . \
  -n flexprice \
  --create-namespace \
  -f examples/values-operators.yaml \
  --wait --timeout 10m

# 4. Run tests
helm test flexprice -n flexprice

# 5. Check status
kubectl get pods -n flexprice
helm status flexprice -n flexprice
```

### With External Services

```bash
helm install flexprice . \
  -n flexprice \
  --create-namespace \
  -f examples/values-external.yaml \
  --set postgres.external.host=pg.example.com \
  --set postgres.external.password=secret \
  --wait --timeout 10m

helm test flexprice -n flexprice
```

### Minimal Development

```bash
helm install flexprice . \
  -n flexprice \
  --create-namespace \
  -f examples/values-minimal.yaml \
  --wait --timeout 5m

helm test flexprice -n flexprice
```

---

## 📖 Where to Go Next

### For New Users
1. **Read** [README.md](README.md) - Understand what this deploys
2. **Start** [QUICK_TEST.md](QUICK_TEST.md) - Run tests in 5 minutes
3. **Choose** [USE_CASES.md](USE_CASES.md) - Pick your deployment scenario
4. **Study** [HELM_TESTS.md](HELM_TESTS.md) - Deep dive into testing

### For Operations/DevOps
1. **Setup** [CI_CD_INTEGRATION.md](CI_CD_INTEGRATION.md) - GitHub/GitLab/Jenkins
2. **Learn** [USE_CASES.md](USE_CASES.md) - All deployment patterns
3. **Troubleshoot** [TESTING.md](TESTING.md) - Manual testing & debugging

### For Developers
1. **Understand** [README.md](README.md) - Architecture overview
2. **Setup** [USE_CASES.md](USE_CASES.md#use-case-4-minimal-development-setup) - Dev environment
3. **Test** [QUICK_TEST.md](QUICK_TEST.md) - Run tests locally
4. **Debug** [HELM_TESTS.md](HELM_TESTS.md) - Test troubleshooting

---

## 🧪 Testing Your Deployment

### All Tests
```bash
helm test flexprice -n flexprice
```

### Specific Test
```bash
helm test flexprice -n flexprice --tests test-api-health
```

### View Test Logs
```bash
kubectl logs -l helm.sh/hook=test -n flexprice -f
```

### What Gets Tested

| Test | Validates |
|------|-----------|
| test-api-health | API server responds to health checks |
| test-postgres-connectivity | Database connectivity (auto-detects external/operator) |
| test-clickhouse-connectivity | Analytics database is accessible |
| test-kafka-connectivity | All message brokers are reachable |
| test-temporal-connectivity | Workflow engine is accessible |
| test-deployments-status | All 3 deployments are ready and healthy |

---

## 🔄 Common Operations

### View Chart Status
```bash
helm status flexprice -n flexprice
```

### Upgrade Chart
```bash
helm upgrade flexprice . -f values.yaml -n flexprice
```

### Rollback to Previous Version
```bash
helm rollback flexprice -n flexprice
```

### View Configuration
```bash
helm get values flexprice -n flexprice
```

### View Rendered Templates
```bash
helm template flexprice . -f values.yaml
```

### Uninstall Chart
```bash
helm uninstall flexprice -n flexprice
```

---

## 📊 File Summary

### Documentation (7 files, ~76KB)
- **QUICK_TEST.md** - Quick reference (5-10 min read)
- **HELM_TESTS.md** - Full testing guide (30 min read)
- **USE_CASES.md** - All 5 scenarios (~60 min read)
- **TESTING.md** - Manual testing (30 min read)
- **CI_CD_INTEGRATION.md** - Pipeline examples (40 min read)
- **DOCUMENTATION_INDEX.md** - This index
- **README.md** - Chart overview

### Templates (20+ files)
- 3 main deployments (API, consumer, worker)
- 3 operator CRD templates
- 6 Helm test pods
- Supporting configs (service, ingress, RBAC, etc.)

### Configuration Examples (3 files)
- Pre-installed operators
- External services only
- Minimal development setup

### Total Lines of Code/Documentation
- **Templates**: ~2000 lines
- **Documentation**: ~4000 lines
- **Configuration**: ~500 lines

---

## 🛠️ Requirements

### Cluster Requirements
- Kubernetes 1.20+
- Helm 3.8+
- Available storage class for PersistentVolumes
- Sufficient resources:
  - Min: 4 CPU, 8GB RAM
  - Recommended: 8 CPU, 16GB RAM for all operators

### Networking
- If external services: Network access to external hosts
- If operators: Available storage for operator CRDs
- Internal pod-to-pod communication enabled

### Secrets/Credentials
- PostgreSQL user/password
- ClickHouse user/password
- Kafka credentials (if using SASL)
- Temporal namespace configuration

---

## 🔗 External Resources

- **Helm**: https://helm.sh/docs/
- **Kubernetes**: https://kubernetes.io/docs/
- **Stackgres**: https://stackgres.io/
- **ClickHouse**: https://clickhouse.com/docs/
- **Redpanda**: https://docs.redpanda.com/
- **Temporal**: https://temporal.io/docs/

---

## 💡 Pro Tips

1. **Always validate before deploying**
   ```bash
   helm template flexprice . | kubectl apply --dry-run=client -f -
   ```

2. **Use values files for different environments**
   ```bash
   helm install flexprice . -f values-prod.yaml -n production
   helm install flexprice . -f values-dev.yaml -n development
   ```

3. **Monitor deployment with multiple terminals**
   ```bash
   # Terminal 1: Watch pods
   kubectl get pods -n flexprice -w
   
   # Terminal 2: View logs
   kubectl logs -l app.kubernetes.io/instance=flexprice -n flexprice -f
   
   # Terminal 3: Run tests
   helm test flexprice -n flexprice
   ```

4. **Keep secrets out of git**
   - Store sensitive values in CI/CD secrets
   - Use `--set` flags or separate secrets files
   - Never commit `values-prod.yaml` with real credentials

5. **Test thoroughly before production**
   - Run all tests against external services first
   - Validate with production-like data volumes
   - Test failover and scaling scenarios
   - Monitor performance metrics

---

## 📞 Support & Troubleshooting

### Chart Issues
- See [README.md](README.md#troubleshooting)
- Check operator pod logs: `kubectl logs -l app=stackgres/clickhouse/redpanda -n <namespace>`

### Test Failures
- See [HELM_TESTS.md](HELM_TESTS.md#troubleshooting)
- View test logs: `kubectl logs -l helm.sh/hook=test -n flexprice`

### Deployment Issues
- See [TESTING.md](TESTING.md)
- Check deployment status: `kubectl describe deployment flexprice-api -n flexprice`

### CI/CD Integration
- See [CI_CD_INTEGRATION.md](CI_CD_INTEGRATION.md)

---

## 📝 Version Information

- **Chart Version**: 0.1.0
- **App Version**: 1.0.0
- **Kubernetes**: 1.20+
- **Helm**: 3.8+

---

**Next Step**: Read [QUICK_TEST.md](QUICK_TEST.md) to get started in 5 minutes!
