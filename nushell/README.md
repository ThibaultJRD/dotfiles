# Nushell Configuration

A modern shell designed for structured data manipulation.

## What is Nushell?

Nushell is a **structured data shell** where everything is typed data (not just strings). Think of it as "PowerShell for Unix" or "SQL meets Bash".

**Key Philosophy**: Pipelines work with structured data (tables, records, lists), not text streams.

## When to Use Nushell

### ✅ Perfect For:
- **Data manipulation**: JSON, CSV, YAML, TOML parsing and transformation
- **API interactions**: Fetch and process API responses
- **Log analysis**: Parse and aggregate log files
- **System automation**: Scripts that work with structured data
- **DevOps tasks**: Process system information, analyze configs
- **One-off data tasks**: Quick data transformations without writing Python/JavaScript

### ❌ Not Recommended For:
- **Daily driver shell**: Pre-1.0, breaking changes every ~4 weeks
- **Interactive use**: Fish has better completions and stability
- **POSIX scripts**: Nushell is intentionally non-POSIX
- **Traditional Unix tools**: They output text, not structured data

## Directory Structure

```
nushell/
├── env.nu              # Environment variables & PATH
├── config.nu           # Main configuration
├── scripts/
│   └── examples.nu     # Data manipulation examples
└── README.md           # This file
```

## Quick Start

### Run Nushell temporarily
```bash
# Start Nushell from your current shell (Fish/Zsh)
nu

# Exit back to your previous shell
exit
```

### Run a one-off command
```bash
# Execute Nushell command from any shell
nu -c "ls | where size > 1mb | select name size"

# Process JSON
nu -c "open data.json | select name email | to csv"

# Analyze logs
nu -c "open app.log | lines | where $it =~ ERROR | length"
```

### Run a Nushell script
```bash
# Execute a .nu script
nu scripts/examples.nu
```

## Why Nushell is Powerful

### Example 1: JSON Processing (Traditional Shell vs Nushell)

**Bash/Zsh (complex, error-prone):**
```bash
curl -s https://api.github.com/users/anthropics/repos \
  | jq -r '.[] | select(.stargazers_count > 100) | "\(.name): \(.stargazers_count)"' \
  | sort -t: -k2 -nr \
  | head -10
```

**Nushell (intuitive, typed):**
```nu
http get https://api.github.com/users/anthropics/repos
| where stargazers_count > 100
| select name stargazers_count
| sort-by stargazers_count --reverse
| first 10
```

### Example 2: CSV Analysis

**Nushell:**
```nu
# Load CSV, group by category, calculate totals
open sales.csv
| group-by category
| transpose key value
| insert total { |row| $row.value | get price | math sum }
| sort-by total --reverse
```

### Example 3: System Information

**Nushell:**
```nu
# Get all running processes, filter, and format
ps
| where cpu > 50
| select name pid cpu mem
| sort-by cpu --reverse
| first 5
```

## Practical Use Cases

### 1. Process Package.json Dependencies
```nu
open package.json
| get dependencies
| transpose package version
| where version =~ "^"
| length
# Count packages with caret versions
```

### 2. Find Large Files
```nu
ls **/*
| where type == file
| where size > 100mb
| select name size
| sort-by size --reverse
```

### 3. Git Commit Analysis
```nu
git log --pretty=format:"%an|%ad|%s" --date=short
| lines
| parse "{author}|{date}|{message}"
| group-by author
| transpose key value
| insert commits { |row| $row.value | length }
| sort-by commits --reverse
```

### 4. API Data Transformation
```nu
# Fetch, filter, transform, and export
http get https://api.example.com/data
| where status == "active"
| select id name email created_at
| to csv
| save output.csv
```

## Integrated Tools

| Tool | Status | Notes |
|------|--------|-------|
| **zoxide** | ✅ Works | `cd` enhanced with zoxide |
| **starship** | ✅ Works | Prompt (optional, commented out in config) |
| **yazi** | ✅ Works | File manager with `y` function |
| **eza** | ⚠️ Partial | Works but outputs text, not Nu tables |
| **bat** | ⚠️ Partial | Works but outputs text |
| **fzf** | ❌ No support | No native integration |

## Learning Nushell

### Essential Commands
```nu
# Help system
help commands         # List all commands
help <command>        # Get help for specific command

# Data exploration
ls | describe        # See data structure
ls | columns         # List column names
ls | first 3         # Get first 3 items

# Type conversions
"123" | into int     # String to integer
date now | into string  # Date to string
open data.json | to csv  # JSON to CSV

# Data manipulation
where size > 1mb     # Filter rows
select name size     # Select columns
sort-by size         # Sort
group-by type        # Group
transpose            # Pivot
```

### Common Patterns
```nu
# Read → Filter → Transform → Output
open data.json
| where status == "active"
| select id name
| to csv

# Aggregate data
open sales.csv
| group-by region
| transpose key value
| insert total { |row| $row.value | get amount | math sum }

# Pipeline with external commands
ls
| where size > 10mb
| get name
| each { |file| echo $"Large file: ($file)" }
```

## Example Scripts

Check out `scripts/examples.nu` for practical examples:
- JSON/CSV processing
- API data fetching
- Log file analysis
- Git repository stats
- System information
- And more!

Run examples:
```bash
nu scripts/examples.nu
```

## Configuration Notes

### env.nu
- Loaded **before** config.nu
- Sets up environment variables
- Configures PATH
- Similar to `.zshenv` or Fish's `conf.d/*.fish`

### config.nu
- Main configuration file
- Sets Nushell behavior and appearance
- Defines aliases and custom commands
- Similar to `.zshrc` or Fish's `config.fish`

## Current Limitations

1. **Pre-1.0 Status** (v0.108.0 as of Oct 2025)
   - Breaking changes every ~4 weeks
   - Pin version in scripts: `#!/usr/bin/env nu --version 0.108.0`

2. **Missing Features**
   - No native fzf integration
   - Job control limited (use tmux)
   - Completions lag behind Fish

3. **External Tools**
   - Traditional Unix tools output text, not Nu tables
   - Requires manual parsing with `parse` or `from` commands

## Recommended Workflow

1. **Use Fish as your daily driver** (interactive shell)
2. **Keep Nushell available** for specific tasks:
   ```bash
   # Quick data task from Fish
   nu -c "open data.json | where active == true | to csv | save output.csv"

   # Enter Nushell for extended data work
   nu
   # ... do data manipulation ...
   exit
   ```

3. **Write Nushell scripts** for automation:
   ```nu
   #!/usr/bin/env nu
   # analyze-logs.nu

   def main [log_file: string] {
       open $log_file
       | lines
       | parse "{timestamp} [{level}] {message}"
       | group-by level
       | transpose key value
       | insert count { |row| $row.value | length }
   }
   ```

## Resources

- **Official Docs**: https://www.nushell.sh/book/
- **Quick Tour**: https://www.nushell.sh/book/quick_tour.html
- **Command Reference**: https://www.nushell.sh/commands/
- **Cookbook**: https://www.nushell.sh/cookbook/

## Migration Note

This configuration is **intentionally minimal** because Nushell is meant as a **secondary tool** for data tasks, not a replacement for your primary shell (Fish).

If Nushell reaches 1.0 with stable APIs and better tooling support, you might reconsider using it as a daily driver. Until then, Fish + Nushell is the optimal combination.

Happy data wrangling! 📊
