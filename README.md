# Shipper GitHub Actions

Reusable GitHub Actions for Shipper deployments.

## Composite Action

Use the composite action when a workflow should run the Shipper CLI with an isolated Composer installation:

```yaml
- uses: shippercli/actions/.github/actions/shipper@2649f5132e10d405dddd77198e42c67035cfff4c
  with:
    command: apply
    project: myapp
    profile: production
    force: true
    providers: |
      shippercli/provider-cpanel:^1.0
```

The action installs the requested `shippercli/cli` version and provider packages together in an isolated Composer tool directory. The reusable workflow below is a separate job-level integration.

### Install providers from GitHub releases

For Forge, Ploi, and Coolify, register the corresponding Git repositories in Composer before invoking the composite action. Keep both steps in the same job so they share `COMPOSER_HOME`. This example assumes the job has checked out a project with a valid `shipper.yml` and set the environment variables that file references. Keep only the repositories and packages your configuration uses.

```yaml
- name: Register Shipper provider repositories
  shell: bash
  run: |
    set -euo pipefail
    export COMPOSER_HOME="$(mktemp -d "${RUNNER_TEMP}/shipper-composer.XXXXXXXX")"
    composer config --global repositories.shipper-forge git https://github.com/shippercli/provider-forge.git
    composer config --global repositories.shipper-ploi git https://github.com/shippercli/provider-ploi.git
    composer config --global repositories.shipper-coolify git https://github.com/shippercli/provider-coolify.git
    printf 'COMPOSER_HOME=%s\n' "$COMPOSER_HOME" >> "$GITHUB_ENV"
- uses: shippercli/actions/.github/actions/shipper@2649f5132e10d405dddd77198e42c67035cfff4c
  with:
    command: validate
    cli-version: '1.0.5'
    providers: |
      shippercli/provider-forge:1.0.0
      shippercli/provider-ploi:2.0.0
      shippercli/provider-coolify:1.0.0
```

## Quick Start

```yaml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  deploy:
    uses: shippercli/actions/.github/workflows/shipper.yml@f944842cb6de035094caf9d520ae6968acf90442
    with:
      cpanel_username: ${{ vars.CPANEL_USERNAME }}
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
    uses: shippercli/actions/.github/workflows/shipper.yml@f944842cb6de035094caf9d520ae6968acf90442
    with:
      project: myapp
      profile: production
      cpanel_username: ${{ vars.CPANEL_USERNAME }}
      providers: |
        shippercli/provider-cpanel:^1.0
    secrets:
      CPANEL_API_TOKEN: ${{ secrets.CPANEL_API_TOKEN }}
```

## Secrets

Configure these in your repository settings under `Settings > Secrets`:

| Secret | Provider | Description |
|--------|----------|-------------|
| `PLOI_API_KEY` | Ploi | Your Ploi API key |
| `FORGE_API_TOKEN` | Forge | Your Forge API token |
| `CPANEL_API_TOKEN` | cPanel | Your cPanel API token |
| `COOLIFY_API_TOKEN` | Coolify | Your Coolify API token |

Reusable-workflow callers forward the secret for each selected provider. Set the repository variable `CPANEL_USERNAME` for the cPanel examples above. For Coolify, set the `coolify_url`, `coolify_server_uuid`, and `coolify_project_uuid` inputs to populate `COOLIFY_URL`, `COOLIFY_SERVER_UUID`, and `COOLIFY_PROJECT_UUID` in the workflow.

The reusable workflow automatically registers the Forge, Ploi, and Coolify Composer repositories when their packages are selected.

## Workflow Steps

1. **Validate** - Validates `shipper.yml` configuration
2. **Plan** - Shows what will be created/deployed
3. **Deploy** - Applies the plan on `main` or on manual dispatch. Set `deploy: false` to run validation and planning only.

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
    uses: shippercli/actions/.github/workflows/shipper.yml@f944842cb6de035094caf9d520ae6968acf90442
    with:
      project: myapp
      profile: ${{ github.event.inputs.profile || 'production' }}
      cpanel_username: ${{ vars.CPANEL_USERNAME }}
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
