# Shipper GitHub Actions

Reusable GitHub Actions for Shipper deployments.

## Composite Action

Use the composite action when a workflow should run the Shipper CLI with an isolated Composer installation:

```yaml
- uses: shippercli/actions/.github/actions/shipper@f31a980b0c6d51b531735d4cd68b2268ad54d193
  with:
    command: apply
    project: myapp
    profile: production
    force: true
    providers: |
      shippercli/provider-cpanel:^1.0
```

The action installs the requested `shippercli/cli` version and provider packages together in an isolated Composer tool directory. The reusable workflow below is a separate job-level integration.

## Quick Start

```yaml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  deploy:
    uses: shippercli/actions/.github/workflows/shipper.yml@v1
    with:
      providers: |
        shippercli/provider-cpanel:^1.0
    secrets:
      CPANEL_API_TOKEN: ${{ secrets.CPANEL_API_TOKEN }}
```

## With Specific Project/Profile

```yaml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  deploy:
    uses: shippercli/actions/.github/workflows/shipper.yml@v1
    with:
      project: myapp
      profile: production
      providers: |
        shippercli/provider-cpanel:^1.0
    secrets:
      CPANEL_API_TOKEN: ${{ secrets.CPANEL_API_TOKEN }}
      FORGE_API_TOKEN: ${{ secrets.FORGE_API_TOKEN }}
```

## Secrets

Configure these in your repository settings under `Settings > Secrets`:

| Secret | Provider | Description |
|--------|----------|-------------|
| `CPANEL_API_TOKEN` | Ploi | Your Ploi API key |
| `FORGE_API_TOKEN` | Forge | Your Forge API token |
| `CPANEL_API_TOKEN` | cPanel | Your cPanel API token |

## Workflow Steps

1. **Validate** - Validates `shipper.yml` configuration
2. **Plan** - Shows what will be created/deployed
3. **Deploy** - Runs the actual deployment (only on `main` branch)

## Example with Full Configuration

```yaml
name: Production Deploy

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      profile:
        description: "Deploy profile"
        required: true
        default: "production"

jobs:
  deploy:
    uses: shippercli/actions/.github/workflows/shipper.yml@v1
    with:
      project: myapp
      profile: ${{ github.event.inputs.profile || 'production' }}
      providers: |
        shippercli/provider-cpanel:^1.0
    secrets:
      CPANEL_API_TOKEN: ${{ secrets.CPANEL_API_TOKEN }}
```

## Local Development

Test the action locally:

```bash
# Validate your shipper.yml
shipper validate

# Preview changes
shipper plan --project=myapp --profile=production

# Deploy (add --force to skip confirmation)
shipper apply --project=myapp --profile=production --force
```
