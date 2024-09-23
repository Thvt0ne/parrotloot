
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
```

Ensure the script has executable permissions:

```bash
chmod +x parrotloot.sh
```

## Usage

```bash
./parrotloot.sh [options]
```

The script takes a variety of options to customize the scanning behavior. The basic command is to supply a URL or IP address to scan.

## Options

| Option                               | Description |
|--------------------------------------|-------------|
| `-u <URL>, --url <URL>`              | URL or IP to scan. The protocol (http/https) is optional. |
| `-o <file>, --output <file>`         | Specify a custom output file. Default is `loot.txt`. |
| `-t <number>, --threads <number>`    | Number of concurrent threads to use for scanning. Default is 1. |
| `-r <number>, --retries <number>`    | Maximum number of retries for failed requests. Default is 3. |
| `-d <seconds>, --delay <seconds>`    | Initial delay between requests to avoid overwhelming the server. Default is 0 seconds. |
| `-m <seconds>, --max-delay <seconds>`| Maximum delay between retries. Default is 5 seconds. |
| `-H <header>, --header <header>`     | Add custom HTTP headers (e.g., `Authorization: Bearer token`). Can be repeated to add multiple headers. |
| `-f, --feroxbuster`                  | Enable directory fuzzing using Feroxbuster. |
| `-fw <file>, --feroxbuster-wordlist <file>` | Provide a custom wordlist for Feroxbuster directory enumeration. |
| `-s, --subdomains`                   | Enable subdomain scanning. |
| `-y <year>, --year <year>`           | Enable time-based filename generation by specifying a year (e.g., `2023`). |
| `-b <month>, --month <month>`        | Use in combination with `--year` to provide a month (e.g., `09`). |
| `-w, --waf-bypass`                   | Enable WAF/IDS bypass techniques using randomized user agents and encoded URLs. |
| `-c, --cloud`                        | Scan for publicly accessible cloud-based storage (AWS S3, Google Cloud Storage, Azure Blob, DigitalOcean Spaces). |
| `-v, --verbose`                      | Enable verbose mode to show skipped and found results. |
| `-vv`                                | Enable very verbose mode to show all output including background tool outputs. |
| `-h, --help`                         | Display this help menu. |

## Examples

### Basic Scan

```bash
./parrotloot.sh -u example.com
```

This command will perform a basic backup file scan on `example.com`.

### Cloud-Based Backup Detection

```bash
./parrotloot.sh -u example.com -c
```

This will scan `example.com` for publicly accessible cloud-based backups (AWS, Google Cloud, Azure, DigitalOcean).

### Multi-Threaded Scanning

```bash
./parrotloot.sh -u example.com -t 20
```

This runs the scan using 20 concurrent threads for faster results.

### Subdomain Enumeration + Directory Fuzzing

```bash
./parrotloot.sh -u example.com -s -f
```

This will perform subdomain scanning and directory fuzzing using Feroxbuster on the identified subdomains.

### Using Custom Headers

```bash
./parrotloot.sh -u example.com -H 'Authorization: Bearer token' -H 'Cookie: session_id=123'
```

This adds custom headers (Authorization and Cookie) to the scan.

### WAF Bypass Techniques

```bash
./parrotloot.sh -u example.com -w
```

This enables WAF/IDS bypass techniques by using randomized user agents and URL encoding.

### Time-Based Filename Search

```bash
./parrotloot.sh -u example.com -y 2023 -b 09
```

This command will search for time-based backup filenames (e.g., `backup_202309.zip`) on `example.com`.

### Verbose and Very Verbose Mode

- **Verbose**: Show skipped and found results.

  ```bash
  ./parrotloot.sh -u example.com -v
  ```

- **Very Verbose**: Show detailed output from all tools and processes.

  ```bash
  ./parrotloot.sh -u example.com -vv
  ```

## Requirements

The following tools are required for ParrotLoot to work:

- **cURL**: Make sure cURL is installed on your system.
- **Feroxbuster** (optional): Required for directory fuzzing. Install Feroxbuster [here](https://github.com/epi052/feroxbuster).
- **jq**: A lightweight and flexible command-line JSON processor.
- **subparrots.sh** (optional): External script required for subdomain scanning if you plan to use the `-s` option.

To install `jq`:

```bash
sudo apt-get install jq
```

Make sure the required wordlists for backup directory names, file extensions, and Feroxbuster wordlists are available in the same directory as the script or provide custom paths.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
