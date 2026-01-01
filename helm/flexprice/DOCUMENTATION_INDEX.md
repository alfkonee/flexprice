# Testing Documentation Index

This index helps you quickly find the right testing documentation for your needs.

## Quick Navigation

### 📌 Start Here
- **[QUICK_TEST.md](QUICK_TEST.md)** - ⏱️ 5-10 minute quick start
  - Copy-paste commands to run tests immediately
  - Basic troubleshooting for common issues
  - One-page reference for `helm test` commands

### 🏗️ Full Implementation Guide
- **[HELM_TESTS.md](HELM_TESTS.md)** - 📖 Comprehensive reference (30+ minutes)
  - Detailed explanation of each test pod
  - What each test validates and why
  - Understanding test output and logs
  - Debugging failed tests

### 📋 Deployment Scenarios
- **[USE_CASES.md](USE_CASES.md)** - 📊 All 5 deployment patterns with complete configs
  - Use Case 1: Pre-installed Operators
  - Use Case 2: External Services Only
  - Use Case 3: Operator Deployment (Full Automation)
  - Use Case 4: Minimal Development Setup
  - Use Case 5: Mixed Configuration
  - Each includes: helm install commands, values files, expected validation, troubleshooting

### 🔧 Manual Testing & Troubleshooting
- **[TESTING.md](TESTING.md)** - 🛠️ Manual testing procedures and debugging
  - How to run tests manually in different environments
  - Step-by-step manual validation procedures
  - Common failure scenarios and fixes
  - Resource monitoring and debugging tools

### ⚙️ CI/CD Integration
- **[CI_CD_INTEGRATION.md](CI_CD_INTEGRATION.md)** - 🚀 Pipeline examples and best practices
  - GitHub Actions workflow
  - GitLab CI pipeline
  - Jenkins pipeline
  - Pre-deployment validation checklist
  - Production deployment pipeline stages
  - Monitoring and rollback procedures

### 📖 Main Documentation
- **[README.md](README.md)** - Overview of chart, installation options, configuration
  - What this chart deploys
  - How to install (operators, pre-installed, external)
  - Configuration reference table
  - Architecture overview

---

## Finding What You Need

### I want to...

**...run tests quickly**
→ Start with [QUICK_TEST.md](QUICK_TEST.md)

**...understand what each test does**
→ Read [HELM_TESTS.md](HELM_TESTS.md#test-descriptions)

**...deploy with pre-installed operators**
→ See [USE_CASES.md](USE_CASES.md#use-case-1-pre-installed-operators)

**...deploy with only external services**
→ See [USE_CASES.md](USE_CASES.md#use-case-2-external-services-only)

**...deploy operators from this chart**
→ See [USE_CASES.md](USE_CASES.md#use-case-3-operator-deployment-full-automation)

**...set up minimal development environment**
→ See [USE_CASES.md](USE_CASES.md#use-case-4-minimal-development-setup)

**...debug test failures**
→ Go to [HELM_TESTS.md](HELM_TESTS.md#troubleshooting)

**...run tests manually**
→ Read [TESTING.md](TESTING.md#manual-testing)

**...integrate tests into CI/CD**
→ See [CI_CD_INTEGRATION.md](CI_CD_INTEGRATION.md)

**...test with GitHub Actions**
→ See [CI_CD_INTEGRATION.md](CI_CD_INTEGRATION.md#github-actions)

**...test with GitLab CI**
→ See [CI_CD_INTEGRATION.md](CI_CD_INTEGRATION.md#gitlab-ci)

**...test with Jenkins**
→ See [CI_CD_INTEGRATION.md](CI_CD_INTEGRATION.md#jenkins-pipeline)

**...understand the deployment architecture**
→ Read [README.md](README.md#architecture)

---

## Documentation Files Summary

| File | Purpose | Length | Read Time | Best For |
|------|---------|--------|-----------|----------|
| QUICK_TEST.md | Quick reference for helm test commands | ~150 lines | 5 min | Running tests immediately |
| HELM_TESTS.md | Comprehensive testing guide | ~700 lines | 30 min | Understanding test details |
| HELM_TESTS.md | Test descriptions and validation logic | ~400 lines | 20 min | Debugging specific tests |
| USE_CASES.md | All 5 deployment scenarios with configs | ~2800 lines | 60+ min | Choosing deployment pattern |
| USE_CASES.md | Use Case 1: Pre-installed Operators | ~500 lines | 15 min | Already have operators |
| USE_CASES.md | Use Case 2: External Services | ~500 lines | 15 min | Using external databases |
| USE_CASES.md | Use Case 3: Full Automation | ~600 lines | 20 min | Want chart to deploy operators |
| USE_CASES.md | Use Case 4: Development Setup | ~400 lines | 10 min | Local development |
| USE_CASES.md | Use Case 5: Mixed Configuration | ~300 lines | 10 min | Some external, some operators |
| TESTING.md | Manual testing procedures | ~800 lines | 30 min | Testing without CI/CD |
| TESTING.md | Troubleshooting guide | ~400 lines | 20 min | Fixing test failures |
| CI_CD_INTEGRATION.md | CI/CD pipeline examples | ~500+ lines | 40 min | GitHub Actions/GitLab/Jenkins |
| README.md | Chart overview and configuration | ~350 lines | 20 min | Getting started |

---

## Test Coverage Matrix

All tests support all 5 use case scenarios. Here's what each test validates:

### By Component

| Component | Test | Pre-installed | External | Operators | Dev | Mixed |
|-----------|------|---------------|----------|-----------|-----|-------|
| **API Server** | test-api-health | ✅ | ✅ | ✅ | ✅ | ✅ |
| **PostgreSQL** | test-postgres-connectivity | ✅ | ✅ | ✅ | ✅ | ✅ |
| **ClickHouse** | test-clickhouse-connectivity | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Kafka** | test-kafka-connectivity | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Temporal** | test-temporal-connectivity | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Deployments** | test-deployments-status | ✅ | ✅ | ✅ | ✅ | ✅ |

### By Test Type

| Test | Type | Validates | Timeout |
|------|------|-----------|---------|
| test-api-health | Health Check | HTTP /health endpoint | 60s |
| test-postgres-connectivity | Connectivity | Database connection | 60s |
| test-clickhouse-connectivity | Connectivity | Analytics DB access | 60s |
| test-kafka-connectivity | Connectivity | All brokers reachable | 60s |
| test-temporal-connectivity | Connectivity | Workflow engine access | 60s |
| test-deployments-status | Readiness | All deployments ready | 300s |

---

## Quick Command Reference

```bash
# Run all tests
helm test flexprice -n flexprice

# Run specific test
helm test flexprice -n flexprice --tests test-api-health

# Debug mode
helm test flexprice -n flexprice --debug

# View test output
kubectl logs -l helm.sh/hook=test -n flexprice

# Check test pod status
kubectl get pods -l helm.sh/hook=test -n flexprice -o wide

# Describe a failed test
kubectl describe pod <test-pod-name> -n flexprice

# Delete test pods manually
kubectl delete pods -l helm.sh/hook=test -n flexprice
```

---

## Recommended Reading Order

### For First-Time Users
1. [README.md](README.md) - Understand what the chart does
2. [QUICK_TEST.md](QUICK_TEST.md) - Learn how to run tests
3. [USE_CASES.md](USE_CASES.md) - Choose your deployment scenario
4. [HELM_TESTS.md](HELM_TESTS.md) - Deep dive into test details

### For Operations/DevOps
1. [CI_CD_INTEGRATION.md](CI_CD_INTEGRATION.md) - CI/CD setup
2. [USE_CASES.md](USE_CASES.md) - Deployment scenarios
3. [TESTING.md](TESTING.md) - Manual testing and troubleshooting

### For Developers
1. [README.md](README.md) - Architecture overview
2. [USE_CASES.md](USE_CASES.md#use-case-4-minimal-development-setup) - Dev setup
3. [QUICK_TEST.md](QUICK_TEST.md) - Running tests locally
4. [HELM_TESTS.md](HELM_TESTS.md) - Understanding test validation

---

## Document Status

| Document | Status | Version | Last Updated |
|----------|--------|---------|--------------|
| QUICK_TEST.md | ✅ Complete | 1.0 | Current |
| HELM_TESTS.md | ✅ Complete | 1.0 | Current |
| USE_CASES.md | ✅ Complete | 1.0 | Current |
| TESTING.md | ✅ Complete | 1.0 | Current |
| CI_CD_INTEGRATION.md | ✅ Complete | 1.0 | Current |
| README.md | ✅ Complete | 1.0 | Current |
| DOCUMENTATION_INDEX.md | ✅ Complete | 1.0 | Current |

---

## Feedback & Contributions

If you find issues with the tests or documentation:

1. Check the [Troubleshooting sections](HELM_TESTS.md#troubleshooting)
2. Review relevant [Use Case documentation](USE_CASES.md)
3. Check existing test logs: `kubectl logs -l helm.sh/hook=test -n flexprice`

For specific issues:
- Chart installation: See [README.md](README.md#troubleshooting)
- Test failures: See [HELM_TESTS.md](HELM_TESTS.md#troubleshooting)
- CI/CD integration: See [CI_CD_INTEGRATION.md](CI_CD_INTEGRATION.md#troubleshooting-cicd-failures)
- Use case questions: See [USE_CASES.md](USE_CASES.md)

---

## Related Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Testing Best Practices](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
- [Stackgres Documentation](https://stackgres.io/)
- [Altinity ClickHouse Operator](https://github.com/Altinity/clickhouse-operator)
- [Redpanda Documentation](https://docs.redpanda.com/)
- [Temporal Workflow Engine](https://temporal.io/docs/)

---

Generated as part of FlexPrice Helm Chart v0.1.0
