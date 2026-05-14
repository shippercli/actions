# Shipper GitHub Actions

Reusable GitHub Actions for Shipper deployments.

## Quick Start

```yaml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  deploy:
    uses: shippercli/actions/.github/workflows/shipper.yml@main
    secrets:
      PLOI_API_KEY: ${{ secrets.PLOI_API_KEY }}
```

## With Specific Project/Profile

```yaml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  deploy:
    uses: shippercli/actions/.github/workflows/shipper.yml@main
    with:
      project: myapp
      profile: production
    secrets:
      PLOI_API_KEY: ${{ secrets.PLOI_API_KEY }}
      FORGE_API_TOKEN: ${{ secrets.FORGE_API_TOKEN }}
```

## Secrets

Configure these in your repository settings under `Settings > Secrets`:

| Secret | Provider | Description |
|--------|----------|-------------|
| `PLOI_API_KEY` | Ploi | Your Ploi API key |
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
    uses: shippercli/actions/.github/workflows/shipper.yml@main
    with:
      project: myapp
      profile: ${{ github.event.inputs.profile || 'production' }}
    secrets:
      PLOI_API_KEY: ${{ secrets.PLOI_API_KEY }}
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