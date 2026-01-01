# Test Script Documentation

Complete guide for running FlexPrice Helm chart validation tests using automated bash and PowerShell scripts.

## Overview

Two test runner scripts are provided for validating the FlexPrice Helm chart across multiple deployment scenarios:

- **`test-chart.sh`** - Bash script for Linux/macOS/Git Bash
- **`test-chart.ps1`** - PowerShell script for Windows/PowerShell Core

Both scripts validate:
1. **Use Case 1**: Pre-Installed Operators
2. **Use Case 2**: External Services  
3. **Use Case 3**: Operator Deployment
4. **Use Case 4**: Minimal Development
5. **Chart Linting**: Helm chart structure validation
6. **Dependencies**: Verify required chart dependencies

## Prerequisites

- **Helm** 3.8 or later
- **kubectl** (optional, only for actual deployment testing)
- **Git Bash** (Windows users using bash) or **PowerShell** 5.1+

### Installation

#### Install Helm

**macOS:**
```bash
brew install helm
```

**Linux (Ubuntu/Debian):**
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

**Windows (PowerShell):**
```powershell
choco install kubernetes-helm
# or
scoop install helm
```

## Using the Bash Script

### Basic Usage

```bash
# Make script executable (first time only)
chmod +x test-chart.sh

# Run all tests
./test-chart.sh

# Run with verbose output
./test-chart.sh -v

# Show help
./test-chart.sh -h
```

### Command Line Options

```bash
./test-chart.sh [OPTIONS]

Options:
  -h, --help      Show help message
  -v, --verbose   Show detailed error output
  -d, --dir       Chart directory (default: ./helm/flexprice)
  -n, --name      Chart name (default: flexprice)
```

### Examples

```bash
# Basic test run
./test-chart.sh

# Verbose mode with full error details
./test-chart.sh -v

# Test custom chart location
./test-chart.sh -d /path/to/helm/flexprice -v

# Test with custom chart name
./test-chart.sh -n my-flexprice-chart
```

### Expected Output

```
========================================
FLEXPRICE HELM CHART VALIDATION SUITE
========================================

Chart: flexprice
Directory: /path/to/helm/flexprice

→ Use Case 1: Pre-Installed Operators
✓ PASSED: Use Case 1: Pre-Installed Operators (1779 lines generated)

→ Use Case 2: External Services
✓ PASSED: Use Case 2: External Services (1695 lines generated)

→ Use Case 3: Operator Deployment
✓ PASSED: Use Case 3: Operator Deployment (12253 lines generated)

→ Use Case 4: Minimal Development
✓ PASSED: Use Case 4: Minimal Development (1730 lines generated)

→ Chart Validation: Helm lint
✓ PASSED: Chart Validation: Chart passes linting

→ Dependencies: Verify chart dependencies
✓ PASSED: Dependencies: All required charts available

========================================
TEST SUMMARY
========================================

Total Tests: 6
Passed: 6
Failed: 0

Passed Tests:
  ✓ Use Case 1: Pre-Installed Operators (1779 lines generated)
  ✓ Use Case 2: External Services (1695 lines generated)
  ✓ Use Case 3: Operator Deployment (12253 lines generated)
  ✓ Use Case 4: Minimal Development (1730 lines generated)
  ✓ Chart Validation: Chart passes linting
  ✓ Dependencies: All required charts available

All tests passed! Chart is ready for deployment.
```

## Using the PowerShell Script

### Basic Usage

```powershell
# Run all tests
.\test-chart.ps1

# Run with verbose output
.\test-chart.ps1 -Verbose

# View script help
Get-Help .\test-chart.ps1
```

### Command Line Options

```powershell
.\test-chart.ps1 [[-Verbose] <SwitchParameter>]

Options:
  -Verbose    Show detailed error output
```

### Examples

```powershell
# Basic test run
.\test-chart.ps1

# Verbose mode with full error details
.\test-chart.ps1 -Verbose

# Run in VS Code terminal
pwsh -File .\test-chart.ps1
```

### Execution Policy

If you encounter execution policy errors on Windows:

```powershell
# Temporarily allow script execution for this session
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Then run the script
.\test-chart.ps1
```

Or run it directly with PowerShell Core:

```powershell
pwsh -File .\test-chart.ps1
```

## CI/CD Integration

### GitHub Actions

Create `.github/workflows/helm-test.yml`:

```yaml
name: Helm Chart Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Helm
        uses: azure/setup-helm@v3
        with:
          version: 'latest'
      
      - name: Run Helm tests
        run: |
          cd helm/flexprice
          chmod +x test-chart.sh
          ./test-chart.sh
```

### GitLab CI

Create `.gitlab-ci.yml`:

```yaml
test:helm:chart:
  image: alpine/helm:latest
  script:
    - cd helm/flexprice
    - chmod +x test-chart.sh
    - ./test-chart.sh -v
  only:
    - merge_requests
    - main
```

### Azure Pipelines

Create `azure-pipelines.yml`:

```yaml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

steps:
  - task: HelmInstaller@0
    inputs:
      helmVersion: 'latest'
  
  - script: |
      cd helm/flexprice
      chmod +x test-chart.sh
      ./test-chart.sh -v
    displayName: 'Run Helm Chart Tests'
```

## Troubleshooting

### Helm Command Not Found

```bash
# Verify helm installation
helm version

# If not installed
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Chart Directory Not Found

Ensure you're running the script from the correct directory:

```bash
# Correct
cd /path/to/flexprice
./helm/flexprice/test-chart.sh

# Or specify the directory
./test-chart.sh -d ./helm/flexprice
```

### Template Rendering Errors

Check for missing examples directory:

```bash
# Verify examples directory exists
ls -la examples/

# Should contain:
# - values-external.yaml
# - values-operators.yaml  
# - values-minimal.yaml
```

### Colors Not Displaying (Bash)

Force color output:

```bash
FORCE_COLOR=1 ./test-chart.sh
```

## Test Results Interpretation

### All Tests Passing ✓

```
Total Tests: 6
Passed: 6
Failed: 0
```

**Status**: Chart is ready for deployment. All use cases validated successfully.

### Some Tests Failing ✗

```
Total Tests: 6
Passed: 4
Failed: 2
```

**Action Required**: Review failed tests in the output. Common issues:
- Missing `examples/values-*.yaml` files
- Helm version incompatibility
- Syntax errors in Chart.yaml or templates

### Template Generation Errors

Run with verbose mode to see full error:

```bash
./test-chart.sh -v
```

## Advanced Usage

### Custom Chart Directory

```bash
# Test chart from different location
./test-chart.sh -d ~/my-charts/flexprice

# PowerShell
# Edit $CHART_DIR variable in script
```

### Running Individual Tests

Extract helm template command from script:

```bash
cd helm/flexprice

# Test single use case
helm template flexprice . -f examples/values-external.yaml

# Lint only
helm lint .

# Check dependencies
helm dependency list .
```

### Saving Test Results

```bash
# Bash - capture output to file
./test-chart.sh -v 2>&1 | tee test-results.txt

# PowerShell - export to file
.\test-chart.ps1 -Verbose | Out-File test-results.txt
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0    | All tests passed |
| 1    | One or more tests failed |

Use in scripts/CI:

```bash
./test-chart.sh
if [ $? -eq 0 ]; then
    echo "Tests passed - proceeding with deployment"
else
    echo "Tests failed - halting deployment"
    exit 1
fi
```

## Next Steps

After tests pass:

1. **Review test output** - Ensure all 6 tests show ✓ PASSED
2. **Test with Kubernetes** - See [HELM_TESTS.md](HELM_TESTS.md) for post-deployment validation
3. **Deploy chart** - Use Helm to deploy to your cluster:

```bash
helm install my-flexprice ./helm/flexprice \
    -f helm/flexprice/examples/values-operators.yaml
```

4. **Monitor deployment** - Check pod status and logs:

```bash
kubectl get pods -l app=flexprice
kubectl logs deployment/flexprice-api -f
```

## Support

For issues with test scripts:

1. Run with verbose flag: `./test-chart.sh -v`
2. Check Helm version: `helm version`
3. Verify Chart.yaml is valid: `helm lint ./helm/flexprice`
4. Review logs in test output

See [TESTING.md](TESTING.md) and [HELM_TESTS.md](HELM_TESTS.md) for additional testing information.
