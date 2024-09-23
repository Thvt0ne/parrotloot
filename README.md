# Saving the README content as a markdown file for the user to download
readme_content = """
# ParrotLoot - Backup and Cloud Storage Detection Script

ParrotLoot is a powerful and customizable bash script designed for detecting hidden backups, cloud storage misconfigurations, and directories on web servers. It also offers the ability to bypass Web Application Firewalls (WAF) and Intrusion Detection Systems (IDS), enumerate subdomains, and scan for specific time-based backup files.

## Features

- **Backup file detection**: Scans for backup files on web servers using multiple filenames and extensions.
- **Cloud-based backup detection**: Identifies publicly accessible cloud storage buckets (AWS S3, Google Cloud Storage, Azure Blob, and DigitalOcean Spaces).
- **Directory fuzzing**: Uses Feroxbuster to identify hidden directories on the target.
- **WAF/IDS Bypass**: Randomizes user agents and URL encodings to evade firewalls and detection systems.
- **Subdomain enumeration**: Uses external tools for subdomain discovery.
- **Time-based backup search**: Searches for backup files with year and month-based naming conventions.
- **Verbosity control**: Detailed output can be controlled with flags for clean or verbose output.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Options](#options)
- [Examples](#examples)
- [Requirements](#requirements)
- [License](#license)

## Installation

Clone the repository to your local machine:

```bash
git clone https://github.com/yourusername/parrotloot.git
cd parrotloot
