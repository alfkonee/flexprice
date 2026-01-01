# FlexPrice Helm Chart - Quick Reference Card

## Run Tests in 30 Seconds

### Linux/macOS/Git Bash
```bash
cd helm/flexprice
chmod +x test-chart.sh
./test-chart.sh
```

### Windows PowerShell
```powershell
cd helm/flexprice
.\test-chart.ps1
```

## Expected Result
```
✓ PASSED: All 6 tests (< 2 minutes)
Status: Chart ready for deployment
```

## Test Details

| Test | Type | Validates |
|------|------|-----------|
| Use Case 1: Pre-Installed Operators | Template | External operators |
| Use Case 2: External Services | Template | External infrastructure |
| Use Case 3: Operator Deployment | Template | Full operator setup |
| Use Case 4: Minimal Development | Template | Dev configuration |
| Chart Lint | Validation | Chart structure |
| Dependencies | Check | Required operators |

## Script Options

### Bash
```bash
./test-chart.sh -v          # Verbose output
./test-chart.sh -h          # Show help
./test-chart.sh -d <path>   # Custom chart directory
./test-chart.sh -n <name>   # Custom chart name
```

### PowerShell
```powershell
.\test-chart.ps1 -Verbose   # Verbose output
Get-Help .\test-chart.ps1   # Show help
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| helm not found | Install Helm: `brew install helm` |
| Permission denied | `chmod +x test-chart.sh` |
| Wrong directory | `cd helm/flexprice` first |
| Execution policy | `Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process` |

## Exit Codes
- **0** = All tests passed ✓
- **1** = Some tests failed ✗

## Key Files

| File | Purpose |
|------|---------|
| test-chart.sh | Bash test runner |
| test-chart.ps1 | PowerShell test runner |
| examples/values-*.yaml | Test configurations |
| templates/tests/ | 6 Helm test pods |

## Documentation

- **Quick Start**: [QUICK_TEST.md](QUICK_TEST.md)
- **Full Guide**: [COMPLETE_TEST_GUIDE.md](COMPLETE_TEST_GUIDE.md)
- **Script Help**: [TEST_SCRIPTS.md](TEST_SCRIPTS.md)
- **CI/CD Setup**: [CI_CD_INTEGRATION.md](CI_CD_INTEGRATION.md)
- **File Inventory**: [TEST_ARTIFACTS.md](TEST_ARTIFACTS.md)

## Next Steps After Tests Pass

```bash
# 1. Deploy chart
helm install my-flexprice ./helm/flexprice

# 2. Run post-deployment tests
helm test my-flexprice

# 3. Check status
kubectl get pods
kubectl logs deployment/flexprice-api -f
```

## CI/CD Integration

Add to your pipeline:

**GitHub Actions:**
```yaml
- run: |
    cd helm/flexprice
    chmod +x test-chart.sh
    ./test-chart.sh
```

**GitLab CI:**
```yaml
test:
  image: alpine/helm:latest
  script:
    - cd helm/flexprice
    - ./test-chart.sh
```

## Chart Info

- **Version**: 0.1.0
- **Status**: Production Ready ✅
- **All Tests**: Passing ✅
- **Operators**: 4 (Stackgres, Altinity ClickHouse, Redpanda, Temporal)
- **Components**: API, Consumer, Worker

---

**Quick Commands:**
```bash
./test-chart.sh                    # Run all tests
./test-chart.sh -v                 # Verbose mode
helm template flexprice .          # Preview manifests
helm install my-fp ./helm/flexprice # Deploy
helm test my-fp                    # Post-deployment tests
```

**For Questions**: See [COMPLETE_TEST_GUIDE.md](COMPLETE_TEST_GUIDE.md)
