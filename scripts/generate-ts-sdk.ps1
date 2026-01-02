# TypeScript SDK Generation Script
# This script generates a modern TypeScript SDK with proper configuration

# Configuration
$apiDir = "api\javascript"
$swaggerFile = "docs\swagger\swagger-3-0.json"
$sdkName = "@flexprice/sdk"
$sdkVersion = "1.0.0"

Write-Host "🚀 Starting TypeScript SDK generation..." -ForegroundColor Cyan

# Check if swagger file exists
if (-not (Test-Path $swaggerFile)) {
    Write-Host "❌ Error: Swagger file not found at $swaggerFile" -ForegroundColor Red
    Write-Host "💡 Please run 'make swagger' first to generate the swagger files" -ForegroundColor Yellow
    exit 1
}

# Check if openapi-generator-cli is installed
if (-not (Get-Command openapi-generator-cli -ErrorAction SilentlyContinue)) {
    Write-Host "📦 Installing OpenAPI Generator CLI..." -ForegroundColor Yellow
    npm install -g @openapitools/openapi-generator-cli
}

# Clean and create API directory while preserving examples
Write-Host "🧹 Cleaning existing SDK directory while preserving examples..." -ForegroundColor Cyan
if (Test-Path $apiDir) {
    # Backup examples directory if it exists
    $examplesDir = Join-Path $apiDir "examples"
    if (Test-Path $examplesDir) {
        Write-Host "📁 Backing up examples directory..." -ForegroundColor Cyan
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $examplesBackup = "${apiDir}_examples_backup_$timestamp"
        Copy-Item -Path $examplesDir -Destination $examplesBackup -Recurse -Force
    }
    
    # Remove the directory
    try {
        Remove-Item -Path $apiDir -Recurse -Force -ErrorAction Stop
    }
    catch {
        Write-Host "⚠️  Could not remove directory normally, creating backup..." -ForegroundColor Yellow
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupDir = "${apiDir}_backup_$timestamp"
        Move-Item -Path $apiDir -Destination $backupDir -Force -ErrorAction SilentlyContinue
    }
}

New-Item -ItemType Directory -Path $apiDir -Force | Out-Null

# Restore examples directory if it was backed up
if (Test-Path $examplesBackup) {
    Write-Host "📁 Restoring examples directory..." -ForegroundColor Cyan
    Move-Item -Path $examplesBackup -Destination (Join-Path $apiDir "examples") -Force
}

# Generate TypeScript SDK
Write-Host "⚙️  Generating TypeScript SDK..." -ForegroundColor Cyan
$generatorResult = openapi-generator-cli generate `
    -i $swaggerFile `
    -g typescript-fetch `
    -o $apiDir `
    --additional-properties=npmName="$sdkName",supportsES6=true,typescriptThreePlus=true,withNodeImports=true,withSeparateModelsAndApi=true,modelPackage=models,apiPackage=apis,enumPropertyNaming=UPPERCASE,stringEnums=true,modelPropertyNaming=camelCase,paramNaming=camelCase,withInterfaces=true,useSingleRequestParameter=true,platform=node,sortParamsByRequiredFlag=true,sortModelPropertiesByRequiredFlag=true,ensureUniqueParams=true,allowUnicodeIdentifiers=false,prependFormOrBodyParameters=false,apiNameSuffix=Api `
    --git-repo-id=javascript-sdk `
    --git-user-id=flexprice `
    --global-property apiTests=false,modelTests=false,apiDocs=true,modelDocs=true,withSeparateModelsAndApi=true,withInterfaces=true,useSingleRequestParameter=true,typescriptThreePlus=true,platform=node

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error: OpenAPI generator failed" -ForegroundColor Red
    Write-Host "💡 Check the swagger file and generator configuration" -ForegroundColor Yellow
    exit 1
}

# Navigate to API directory
Push-Location $apiDir

try {
    # Configure package.json
    Write-Host "📝 Configuring package.json..." -ForegroundColor Cyan
    
    $packageJson = @"
{
  "name": "@flexprice/sdk",
  "version": "$sdkVersion",
  "description": "Official TypeScript/JavaScript SDK of Flexprice",
  "author": "Flexprice",
  "repository": {
    "type": "git",
    "url": "https://github.com/flexprice/javascript-sdk.git"
  },
  "main": "./dist/index.js",
  "typings": "./dist/index.d.ts",
  "module": "./dist/index.js",
  "sideEffects": false,
  "scripts": {
    "build": "tsc",
    "prepare": "npm run build",
    "test": "jest",
    "lint": "eslint src/**/*.ts",
    "lint:fix": "eslint src/**/*.ts --fix"
  },
  "type": "module",
  "types": "./dist/index.d.ts",
  "engines": {
    "node": ">=16.0.0"
  },
  "keywords": ["flexprice", "sdk", "typescript", "javascript", "api", "billing", "pricing", "es7", "esmodules", "fetch"],
  "files": ["dist", "README.md"],
  "exports": {
    ".": {
      "import": "./dist/index.js",
      "require": "./dist/index.cjs",
      "types": "./dist/index.d.ts"
    },
    "./package.json": "./package.json"
  }
}
"@
    
    Set-Content -Path "package.json" -Value $packageJson
    
    # Remove invalid dependencies
    Write-Host "🔧 Fixing package.json dependencies..." -ForegroundColor Cyan
    npm pkg delete devDependencies.expect 2>$null
    npm pkg delete devDependencies."@types/jest" 2>$null
    
    # Install TypeScript dependencies
    Write-Host "📦 Installing TypeScript dependencies..." -ForegroundColor Cyan
    npm install --save-dev `
        typescript@^5.0.0 `
        "@types/node@^20.0.0" `
        "@typescript-eslint/eslint-plugin@^6.0.0" `
        "@typescript-eslint/parser@^6.0.0" `
        eslint@^8.0.0 `
        jest@^29.5.0 `
        ts-jest@^29.1.0 `
        "@types/jest@^29.5.0"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error: Failed to install TypeScript dependencies" -ForegroundColor Red
        Write-Host "💡 Check npm configuration and network connectivity" -ForegroundColor Yellow
        Write-Host "⚠️  Continuing with build..." -ForegroundColor Yellow
    }
    
    # Create TypeScript configuration
    Write-Host "⚙️  Creating TypeScript configuration..." -ForegroundColor Cyan
    $tsConfig = @"
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "moduleResolution": "node",
    "lib": ["ES2022", "DOM"],
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "allowSyntheticDefaultImports": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": false,
    "incremental": true,
    "tsBuildInfoFile": "./dist/.tsbuildinfo"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "**/*.test.ts", "**/*.spec.ts"]
}
"@
    Set-Content -Path "tsconfig.json" -Value $tsConfig
    
    # Create Jest configuration
    Write-Host "⚙️  Creating Jest configuration..." -ForegroundColor Cyan
    $jestConfig = @"
export default {
  preset: 'ts-jest/presets/default-esm',
  testEnvironment: 'node',
  extensionsToTreatAsEsm: ['.ts'],
  globals: {
    'ts-jest': {
      useESM: true,
    },
  },
  moduleNameMapper: {
    '^(\\.{1,2}/.*)\\.js$': '$1',
  },
  transform: {
    '^.+\\.ts$': ['ts-jest', {
      useESM: true,
    }],
  },
  testMatch: [
    '**/__tests__/**/*.test.ts',
    '**/?(*.)+(spec|test).ts',
  ],
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/**/*.test.ts',
    '!src/**/*.spec.ts',
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html'],
};
"@
    Set-Content -Path "jest.config.js" -Value $jestConfig
    
    # Create ESLint configuration
    Write-Host "⚙️  Creating ESLint configuration..." -ForegroundColor Cyan
    $eslintConfig = @"
module.exports = {
  parser: '@typescript-eslint/parser',
  extends: [
    'eslint:recommended',
    '@typescript-eslint/recommended',
  ],
  parserOptions: {
    ecmaVersion: 2022,
    sourceType: 'module',
    project: './tsconfig.json',
  },
  plugins: ['@typescript-eslint'],
  rules: {
    '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    '@typescript-eslint/explicit-function-return-type': 'off',
    '@typescript-eslint/explicit-module-boundary-types': 'off',
    '@typescript-eslint/no-explicit-any': 'warn',
    '@typescript-eslint/no-non-null-assertion': 'warn',
    'prefer-const': 'error',
    'no-var': 'error',
  },
  env: {
    node: true,
    es2022: true,
  },
  ignorePatterns: ['dist/', 'node_modules/', '*.js'],
};
"@
    Set-Content -Path ".eslintrc.js" -Value $eslintConfig
    
    # Create .gitignore
    Write-Host "⚙️  Creating .gitignore..." -ForegroundColor Cyan
    $gitignore = @"
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Build outputs
dist/
build/
*.tsbuildinfo

# Coverage
coverage/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
logs/
*.log
"@
    Set-Content -Path ".gitignore" -Value $gitignore
    
    # Build the project
    Write-Host "🔨 Building TypeScript project..." -ForegroundColor Cyan
    npm run build
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error: TypeScript build failed" -ForegroundColor Red
        Write-Host "💡 Check the build output above for errors" -ForegroundColor Yellow
        exit 1
    }
}
finally {
    Pop-Location
}

# Copy custom files
Write-Host "🔄 Copying custom files..." -ForegroundColor Cyan
$copyScript = "scripts\copy-custom-files.ps1"
if (Test-Path $copyScript) {
    powershell -ExecutionPolicy Bypass -File $copyScript javascript
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Warning: Custom files copy failed, but continuing..." -ForegroundColor Yellow
    }
}
else {
    Write-Host "⚠️  Custom files copy script not found" -ForegroundColor Yellow
}

Write-Host "✅ TypeScript SDK generated successfully!" -ForegroundColor Green
Write-Host "📁 Location: $apiDir" -ForegroundColor Green
Write-Host "🚀 Ready for development and publishing" -ForegroundColor Green

Write-Host "`n💡 Next steps:" -ForegroundColor Yellow
Write-Host "  1. cd $apiDir"
Write-Host "  2. npm run test    # Run tests"
Write-Host "  3. npm run lint    # Check code quality"
Write-Host "  4. npm run build   # Build the project"
Write-Host "  5. npm publish     # Publish to npm (when ready)"
Write-Host "`n💡 Custom files management:" -ForegroundColor Cyan
Write-Host "  - Add custom files to: api\custom\javascript\"
Write-Host "  - They will be automatically copied on next regeneration"
