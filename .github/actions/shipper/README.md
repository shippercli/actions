# Shipper CLI GitHub Action

This composite action installs Shipper and provider plugins into an isolated Composer tool directory, then runs the CLI against the checked-out application. It does not modify the application's `composer.json`, `composer.lock`, or `vendor` directory.

## Usage

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: shippercli/actions/.github/actions/shipper@v1
        with:
          command: apply
          project: api
          profile: production
          force: true
          cli-version: '^1.0'
          providers: |
            shippercli/provider-ploi:^1.0
        env:
          PLOI_API_KEY: ${{ secrets.PLOI_API_KEY }}
```

Install multiple providers in one tool environment:

```yaml
with:
  providers: |
    shippercli/provider-ploi:^1.0
    shippercli/provider-cpanel:^1.0
    shippercli/provider-forge:^1.0
```

The `providers` value contains one Composer package per line. Each package may include a Composer constraint after `:`. All packages are installed together with `shippercli/cli`, so plugin discovery sees them from the same Composer installation.

## Inputs

| Input | Required | Default | Description |
| --- | --- | --- | --- |
| `command` | Yes | - | `validate`, `plan`, `apply`, `status`, `logs`, `rollback`, or `destroy` |
| `project` | No | - | Project name from `shipper.yml` |
| `profile` | No | - | Deployment profile |
| `force` | No | `false` | Skip confirmation prompts |
| `release` | No | - | Provider release identifier for rollback |
| `lines` | No | - | Maximum log lines |
| `working-directory` | No | `.` | Directory containing `shipper.yml` |
| `php-version` | No | `8.3` | PHP used for the isolated tool installation |
| `cli-version` | No | `^1.0` | Composer constraint for `shippercli/cli` |
| `providers` | Yes | - | Provider Composer packages, one per line |

## Installation and caching

The action sets up PHP and Composer, then installs Shipper and all requested providers under `$RUNNER_TOOL_CACHE` (falling back to `$RUNNER_TEMP`). The cache key includes the runner OS, PHP version, CLI constraint, and canonical provider list. The application checkout is used only as the `working-directory` when running Shipper.

Pin this action to a release tag or commit SHA, such as `@v1` or `@<sha>`, rather than `@main`.

## Environment variables

Provider credentials are passed through the action step's `env` block. See each provider package's documentation for the required variables. Preview deployments may also pass `GITHUB_PR_NUMBER` and `GITHUB_HEAD_REF`.

## Output

| Output | Description |
| --- | --- |
| `exit-code` | Exit code returned by the Shipper command |
