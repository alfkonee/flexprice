# Cross-Platform Makefile Support

This Makefile has been updated to be **OS-agnostic** and **container runtime-agnostic**, supporting:
- **Operating Systems**: Windows, Linux, macOS
- **Container Runtimes**: Docker, Podman

## Key Features

### 1. Automatic OS Detection
The Makefile automatically detects your operating system and uses appropriate commands:
- **Windows**: Uses PowerShell scripts (`.ps1`)
- **Unix/Linux/macOS**: Uses Bash scripts (`.sh`)

### 2. Automatic Container Runtime Detection
The Makefile automatically detects and uses either Docker or Podman:
- Checks for Docker first
- Falls back to Podman if Docker is not available
- You can override by setting `CONTAINER_RUNTIME` environment variable

### 3. Platform-Specific Commands
All shell-specific commands have been abstracted:
- File operations (`rm`, `mkdir`, etc.)
- Command availability checks (`which`, `where`)
- Date formatting
- Sleep commands

## Usage

### Basic Commands
All commands work the same across platforms:

```bash
# Windows (PowerShell or CMD)
make up
make down
make dev-setup
make test

# Linux/macOS (Bash)
make up
make down
make dev-setup
make test
```

### Override Container Runtime
```bash
# Use Docker explicitly
CONTAINER_RUNTIME=docker make up

# Use Podman explicitly  
CONTAINER_RUNTIME=podman make up
```

## Script Structure

For each functionality, there are now platform-specific scripts:

### Bash Scripts (.sh) - For Unix/Linux/macOS
- `scripts/migrate-clickhouse.sh`
- `scripts/clean-volumes.sh`
- `scripts/apply-migration.sh`
- `scripts/fix_swagger_refs.sh`
- `scripts/copy-custom-files.sh`
- `scripts/generate-ts-sdk.sh`
- `scripts/install-typst.sh`
- `scripts/test-github-workflow.sh`
- `scripts/show-custom-files.sh`

### PowerShell Scripts (.ps1) - For Windows
- `scripts/migrate-clickhouse.ps1`
- `scripts/clean-volumes.ps1`
- `scripts/apply-migration.ps1`
- `scripts/fix_swagger_refs.ps1`
- `scripts/copy-custom-files.ps1`
- `scripts/generate-ts-sdk.ps1`
- `scripts/install-typst.ps1`
- `scripts/test-github-workflow.ps1`
- `scripts/show-custom-files.ps1`

## Requirements

### Windows
- PowerShell 5.1 or higher (comes with Windows)
- Docker Desktop or Podman
- Make for Windows (install via Chocolatey: `choco install make` or Scoop: `scoop install make`)

### Linux/macOS
- Bash (pre-installed)
- Docker or Podman
- Make (usually pre-installed)

## Troubleshooting

### Make not found on Windows
Install Make using one of these methods:
```powershell
# Using Chocolatey
choco install make

# Using Scoop
scoop install make
```

### Script execution policy errors on Windows
If you get execution policy errors, run PowerShell as Administrator and execute:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Container runtime not detected
Ensure Docker or Podman is installed and running:
```bash
# Check Docker
docker version

# Check Podman
podman version
```

## Examples

### Development Setup
```bash
# Complete development environment setup
make dev-setup

# Start infrastructure only
make up

# Stop all services
make down

# Clean and restart
make clean-start
```

### SDK Generation
```bash
# Generate all SDKs
make generate-sdk

# Generate specific SDK
make generate-javascript-sdk
make generate-python-sdk
make generate-go-sdk
```

### Database Operations
```bash
# Run migrations
make migrate-ent

# Generate migration file
make generate-migration

# Apply specific migration
make apply-migration file=path/to/migration.sql
```

## Contributing

When adding new make targets that require shell scripting:
1. Create both `.sh` and `.ps1` versions of any scripts
2. Use the `$(SHELL_CMD)` variable in the Makefile
3. Test on both Windows and Unix platforms
4. Update this README with new commands

## Notes

- The Makefile uses variables like `$(RM)`, `$(MKDIR)`, `$(WHICH)` for cross-platform compatibility
- Script paths automatically use the correct extension based on the OS
- All scripts handle errors gracefully and provide helpful messages
- Container commands work identically with both Docker and Podman
