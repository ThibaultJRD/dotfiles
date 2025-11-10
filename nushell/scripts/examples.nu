# ==============================================================================
# Nushell Data Manipulation Examples
# ==============================================================================
# This file contains examples showing why Nushell excels at data manipulation

# --- Example 1: JSON Processing ---
# Parse JSON and extract specific fields
def "process json-file" [file: string] {
    open $file
    | from json
    | select name email age
    | where age > 25
    | sort-by age
}

# Example usage:
# process json-file users.json

# --- Example 2: CSV Analysis ---
# Analyze CSV data with aggregations
def "analyze csv" [file: string] {
    open $file
    | from csv
    | group-by category
    | transpose key value
    | insert count { |row| $row.value | length }
    | insert total { |row| $row.value | get price | math sum }
    | select key count total
}

# Example usage:
# analyze csv sales.csv

# --- Example 3: API Data Fetching ---
# Fetch data from API and process it
def "fetch github-repos" [user: string] {
    http get $"https://api.github.com/users/($user)/repos"
    | select name stargazers_count language updated_at
    | sort-by stargazers_count --reverse
    | first 10
}

# Example usage:
# fetch github-repos torvalds

# --- Example 4: Log File Analysis ---
# Parse and analyze log files
def "analyze logs" [file: string] {
    open $file
    | lines
    | parse "{timestamp} [{level}] {message}"
    | group-by level
    | transpose key value
    | insert count { |row| $row.value | length }
    | sort-by count --reverse
}

# Example usage:
# analyze logs app.log

# --- Example 5: Directory Size Analysis ---
# Analyze disk usage by directory
def "disk usage" [path: string = "."] {
    ls $path
    | where type == dir
    | insert size_mb {|row|
        du $row.name
        | get apparent
        | into int
        | $in / 1_000_000
    }
    | select name size_mb
    | sort-by size_mb --reverse
}

# Example usage:
# disk usage ~/Projects

# --- Example 6: Process Management ---
# Find processes by port and show details
def "find port" [port: int] {
    ^lsof -i $":($port)"
    | from ssv --noheaders
    | select 0 1 8
    | rename command pid name
}

# Example usage:
# find port 3000

# --- Example 7: Git Repository Analysis ---
# Analyze git commits
def "git stats" [] {
    ^git log --pretty=format:"%an|%ae|%ad|%s" --date=short
    | lines
    | parse "{author}|{email}|{date}|{message}"
    | group-by author
    | transpose key value
    | insert commits { |row| $row.value | length }
    | select key commits
    | sort-by commits --reverse
}

# Example usage (in a git repo):
# git stats

# --- Example 8: Environment Variables ---
# Pretty print environment variables
def "show env" [pattern?: string] {
    if $pattern == null {
        $env | transpose key value
    } else {
        $env
        | transpose key value
        | where key =~ $pattern
    }
}

# Example usage:
# show env PATH
# show env

# --- Example 9: Package.json Analysis ---
# Analyze dependencies in package.json
def "analyze package-json" [] {
    open package.json
    | get dependencies?
    | transpose package version
    | insert type { |_| "dependency" }
    | append (
        open package.json
        | get devDependencies?
        | transpose package version
        | insert type { |_| "devDependency" }
    )
    | sort-by package
}

# Example usage (in a Node.js project):
# analyze package-json

# --- Example 10: System Information ---
# Get system information in a structured format
def "system info" [] {
    {
        hostname: (hostname | str trim)
        os: $nu.os-info.name
        arch: $nu.os-info.arch
        kernel: $nu.os-info.kernel_version
        uptime: (uptime | str trim)
        shell_version: $nu.version
    }
}

# Example usage:
# system info | to json
# system info | to yaml
