# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a CDC (疾管署) Modeling Hub for infectious disease forecasting. It uses GitHub as a collaboration platform to integrate prediction models from research teams across Taiwan.

## Key Commands

### Validation
```bash
# Validate CSV files
python validate_csv.py

# Run R validation scripts
Rscript validation/validate_forecast.R
Rscript validation/run_all_checks.R
```

### R Package Installation
```bash
Rscript -e "install.packages(c('tidyverse', 'gh', 'git2r', 'yaml', 'plumber', 'cronR', 'keyring'))"
```

### GitHub Actions
Workflows are triggered automatically:
- `validate-csv.yml` - Validates CSV files on push to `data/**/*.csv`
- `validate-submission.yml` - Validates forecast submissions
- `deploy-website.yml` - Deploys website via GitHub Pages
- `backup.yml` - Backup operations
- `weekly-integration.yml` - Weekly integration tasks

## Architecture

```
├── data/                    # CSV data files (forecast data)
├── validation/              # R validation scripts
│   ├── validate_forecast.R  # Single file validation
│   └── run_all_checks.R     # Batch validation
├── scripts/                 # Operational scripts
│   ├── push_to_github.R     # R Server → GitHub sync
│   ├── sync_with_github.R   # Bidirectional sync
│   ├── backup_critical_data.R
│   ├── webhook_api.R        # Webhook receiver (plumber)
│   └── disaster_recovery.sh
├── templates/               # Quarto website templates
├── workflows/               # Additional GitHub Actions templates
└── .github/workflows/       # Active GitHub Actions
```

## Data Format

### Forecast CSV
Required columns: `forecast_date`, `target`, `target_end_date`, `location`, `type`, `quantile`, `value`

### Metadata YAML
Required fields: `team_name`, `team_abbr`, `model_name`, `model_version`, `methods`, `data_inputs`

## System Requirements

- Git 2.0+
- R 4.0+
- Python (for CSV validation)
- GitHub CLI (`gh`) for repository operations
