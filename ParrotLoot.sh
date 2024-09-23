#!/bin/bash

# Default output file
output_file="loot.txt"
max_concurrent_jobs=1   # Default number of parallel jobs; can be overridden with -t option
initial_delay=0         # Initial delay between requests in seconds
max_delay=5             # Maximum delay between requests in seconds
delay_increment=0.5     # Amount to increase delay upon error
delay_decrement=0.1     # Amount to decrease delay upon success
current_delay=$initial_delay
max_retries=3           # Default number of retries for failed requests
run_feroxbuster=0       # Flag to run feroxbuster, off by default
feroxbuster_wordlist="" # Default: no wordlist for feroxbuster
verbosity=0             # Default verbosity level: show only found results
custom_headers=()       # Array to hold custom headers
run_subdomain_scan=0    # Flag to enable subdomain scanning
time_based_search=0     # Flag for enabling time-based searches
year=""                 # Year for time-based search
month=""                # Month for time-based search
waf_bypass=0            # Flag for enabling WAF/IDS bypass
cloud_scan=0            # Flag to enable cloud-based backup detection

# Color definitions
CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
MAGENTA="\033[0;35m"
NC="\033[0m"  # No color

# Paths to wordlists (adjust these paths to where your wordlists are stored)
backup_dirs_wordlist="backup_dirs.txt"
filenames_wordlist="filenames.txt"   # We will use this to load additional filenames
extensions_wordlist="extensions.txt"
ferox_wordlist="ferox_wordlist.txt"  # Default wordlist for feroxbuster (if provided)

# Array of acceptable content types
acceptable_types=(
    "application/zip"
    "application/octet-stream"
    "application/json"
    "application/x-tar"
    "text/plain"
    "application/gzip"
    "application/x-bzip2"
    "application/x-7z-compressed"
    "application/sql"
)

# Array of user agents for WAF/IDS evasion
user_agents=(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15"
    "Mozilla/5.0 (Linux; Android 8.0; SM-G955U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.84 Mobile Safari/537.36"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:79.0) Gecko/20100101 Firefox/79.0"
)


cat <<'EOF'

.---.                       .-.      .-.               .-. 
: .; :                     .' `.     : :              .' `.
:  _.'.--.  .--. .--.  .--.`. .'     : :    .--.  .--.`. .'
: :  ' .; ; : ..': ..'' .; :: :      : :__ ' .; :' .; :: : 
:_;  `.__,_;:_;  :_;  `.__.':_; _____:___.'`.__.'`.__.':_; 
                               :_____:      by:thvt0ne               

						
EOF


# Function to display the help menu
show_help() {
    echo -e "${CYAN}Usage: ./parrotloot.sh [options]${NC}"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    
    echo -e "  ${GREEN}-u <URL>, --url <URL>${NC}"
    echo -e "      ${CYAN}URL or IP to scan.${NC} The protocol (http/https) is optional. For example, you can simply provide 'example.com' or '8.8.8.8'."

    echo -e "  ${GREEN}-o <file>, --output <file>${NC}"
    echo -e "      ${CYAN}Specify a custom output file.${NC} If not provided, the default output file is 'loot.txt'."

    echo -e "  ${GREEN}-t <number>, --threads <number>${NC}"
    echo -e "      ${CYAN}Number of concurrent threads to run for faster scanning.${NC} Default is 1, but you can set it higher (e.g., '20' threads)."

    echo -e "  ${GREEN}-r <number>, --retries <number>${NC}"
    echo -e "      ${CYAN}Maximum number of retries for failed requests (default: 3).${NC}"

    echo -e "  ${GREEN}-d <seconds>, --delay <seconds>${NC}"
    echo -e "      ${CYAN}Initial delay between requests.${NC} Useful to avoid overwhelming servers (default: 0 seconds)."

    echo -e "  ${GREEN}-m <seconds>, --max-delay <seconds>${NC}"
    echo -e "      ${CYAN}Maximum delay between retries.${NC} Useful for adjusting retry delays (default: 5 seconds)."

    echo -e "  ${GREEN}-H <header>, --header <header>${NC}"
    echo -e "      ${CYAN}Add custom HTTP headers.${NC} For example, 'Authorization: Bearer token' or 'Cookie: session_id=123'. You can use multiple headers by repeating the '-H' flag."

    echo -e "  ${GREEN}-f, --feroxbuster${NC}"
    echo -e "      ${CYAN}Enable directory fuzzing using feroxbuster.${NC} This will scan for hidden directories on the provided URL/domain."

    echo -e "  ${GREEN}-fw <file>, --feroxbuster-wordlist <file>${NC}"
    echo -e "      ${CYAN}Provide a custom wordlist for feroxbuster to use.${NC} This can be helpful for more focused directory enumeration."

    echo -e "  ${GREEN}-s, --subdomains${NC}"
    echo -e "      ${CYAN}Enable subdomain scanning.${NC} This option will call 'subparrots.sh' to enumerate subdomains for the provided URL/domain."

    echo -e "  ${GREEN}-y <year>, --year <year>${NC}"
    echo -e "      ${CYAN}Enable time-based filename generation.${NC} Provide a year (e.g., '2023') to search for backups with year-based names."

    echo -e "  ${GREEN}-b <month>, --month <month>${NC}"
    echo -e "      ${CYAN}In combination with --year, provide a month.${NC} This searches for backups with year and month-based names (e.g., 'backup_202309')."

    echo -e "  ${GREEN}-w, --waf-bypass${NC}"
    echo -e "      ${CYAN}Enable WAF/IDS bypass techniques.${NC} This uses random user agents and encoded URL paths to avoid detection by Web Application Firewalls or Intrusion Detection Systems."

    echo -e "  ${GREEN}-c, --cloud${NC}"
    echo -e "      ${CYAN}Enable cloud-based backup detection.${NC} This scans for public cloud storage backups (e.g., AWS S3, Google Cloud Storage, Azure Blob Storage)."
    
    echo -e "  ${GREEN}-v, --verbose${NC}"
    echo -e "      ${CYAN}Enable verbose mode.${NC} This provides additional details and progress information during the scan."

    echo -e "  ${GREEN}-vv${NC}"
    echo -e "      ${CYAN}Enable very verbose mode (all tool output).${NC}"

    echo -e "  ${GREEN}-h, --help${NC}"
    echo -e "      ${CYAN}Show this help menu.${NC}"

    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    
    echo -e "  ${GREEN}./parrotloot.sh -u example.com${NC}"
    echo -e "      ${CYAN}Perform a basic backup scan on 'example.com'.${NC}"

    echo -e "  ${GREEN}./parrotloot.sh -u example.com -c${NC}"
    echo -e "      ${CYAN}Scan 'example.com' for cloud-based backups.${NC}"

    echo -e "  ${GREEN}./parrotloot.sh -u example.com -t 20${NC}"
    echo -e "      ${CYAN}Run the scan using 20 concurrent threads for faster processing.${NC}"

    echo -e "  ${GREEN}./parrotloot.sh -u example.com -s -f${NC}"
    echo -e "      ${CYAN}Perform a subdomain scan along with directory fuzzing using feroxbuster.${NC}"

    echo -e "  ${GREEN}./parrotloot.sh -u example.com -H 'Authorization: Bearer token' -H 'Cookie: session_id=123'${NC}"
    echo -e "      ${CYAN}Add custom headers to the scan.${NC}"

    echo -e "  ${GREEN}./parrotloot.sh -u example.com -w${NC}"
    echo -e "      ${CYAN}Enable WAF/IDS bypass techniques.${NC}"

    echo -e "  ${GREEN}./parrotloot.sh -u example.com -y 2023 -b 09${NC}"
    echo -e "      ${CYAN}Search for time-based backup filenames.${NC}"

    echo -e "  ${GREEN}./parrotloot.sh -u example.com -v${NC}"
    echo -e "      ${CYAN}Run the scan in verbose mode, providing detailed output.${NC}"

    echo ""
    echo -e "${CYAN}This tool is designed for backup and cloud storage detection, subdomain scanning, WAF evasion, and directory fuzzing.${NC}"
    exit 0
}


# Initialize logging
error_log="error_log.txt"
> "$error_log"  # Clear error log at the beginning

log_error() {
    echo "$(date): $1" >> "$error_log"
}

get_random_user_agent() {
    echo "${user_agents[RANDOM % ${#user_agents[@]}]}"
}

generate_base_names() {
    local domain=$1
    local domain_name=""
    local tld=""
    local parts=()
    declare -A base_names_dict

    # Remove protocol (http:// or https://) and 'www.'
    domain=${domain#*//}
    domain=${domain#www.}

    # Split domain into parts
    IFS='.' read -r -a parts <<< "$domain"

    # Extract domain_name and tld
    if [ ${#parts[@]} -ge 2 ]; then
        domain_name=${parts[0]}
        tld=$(IFS=_; echo "${parts[@]:1}")
    else
        domain_name=${parts[0]}
        tld=""
    fi

    # Initialize an array to hold base names in desired order
    base_names_ordered=()

    # Add custom filenames in desired order
    base_names_ordered+=("$domain_name")                          # e.g., nour
    base_names_ordered+=("${domain_name}_${tld//_/}")             # e.g., nour_netsa

    # Time-based filename generation (YYYYMM, YYYY_MM, etc.)
    if [ "$time_based_search" -eq 1 ]; then
        if [ -n "$year" ]; then
            base_names_ordered+=("${domain_name}_${year}${month}") # e.g., nour_202309
            base_names_ordered+=("${domain_name}_${year}_${month}") # e.g., nour_2023_09
        fi
    fi

    # Generate the rest of the filenames (keeping only one logic for similar entries)
    base_names_dict["$domain_name"]=1                             # e.g., nour
    base_names_dict["${domain_name}_${tld}"]=1                    # e.g., nour_net_sa
    base_names_dict["${domain_name}_${domain_name}"]=1            # e.g., nour_nour
    base_names_dict["${domain_name}-${tld//_/}"]=1                # e.g., nour-netsa
    base_names_dict["${domain_name}_${domain_name}_backup"]=1     # e.g., nour_nour_backup
    base_names_dict["backup_${domain_name}"]=1                    # e.g., backup_nour
    base_names_dict["backup-${domain_name}-${tld//_/}"]=1         # e.g., backup-nour-netsa
    base_names_dict["${domain_name}_database"]=1                  # e.g., nour_database
    base_names_dict["${domain_name}_dump"]=1                      # e.g., nour_dump

    # Read additional filenames from wordlist
    if [[ -f "$filenames_wordlist" ]]; then
        while IFS= read -r line; do
            base_names_dict["$line"]=1
        done < "$filenames_wordlist"
    fi

    # Remove duplicates from the custom ordered list
    declare -A seen
    unique_base_names_ordered=()
    for name in "${base_names_ordered[@]}"; do
        if [[ -z "${seen[$name]}" ]]; then
            unique_base_names_ordered+=("$name")
            seen[$name]=1
        fi
    done

    # Remove the ordered base names from the dictionary to avoid duplication
    for name in "${unique_base_names_ordered[@]}"; do
        unset base_names_dict["$name"]
    done

    # Append the rest of the base names from the dictionary
    base_names_remaining=("${!base_names_dict[@]}")

    # Combine the ordered base names and the remaining base names
    base_names=("${unique_base_names_ordered[@]}" "${base_names_remaining[@]}")

    echo "${base_names[@]}"
}

# Function to implement WAF/IDS evasion techniques
waf_bypass_methods() {
    local url=$1
    local encoded_url

    # Randomize user agents for every request
    local user_agent=$(get_random_user_agent)

    # URL encoding the path
    encoded_url=$(echo "$url" | jq -sRr @uri)

    # Slight delay (optional)
    if [[ "$waf_bypass" -eq 1 ]]; then
        sleep $(awk -v min=0.5 -v max=1.5 'BEGIN{srand(); print min+rand()*(max-min)}')
    fi

    # Return the modified URL and user-agent
    echo "$encoded_url" "$user_agent"
}

check_connectivity() {
    local url=$1
    local user_agent=$(get_random_user_agent)

    # Prepare custom headers for curl
    local header_args=()
    for header in "${custom_headers[@]}"; do
        header_args+=("-H" "$header")
    done

    # Apply WAF bypass techniques if enabled
    if [[ "$waf_bypass" -eq 1 ]]; then
        url_and_user_agent=$(waf_bypass_methods "$url")
        url=$(echo "$url_and_user_agent" | awk '{print $1}')
        user_agent=$(echo "$url_and_user_agent" | awk '{print $2}')
    fi

    # Make the curl request with custom headers
    if curl -s --head --insecure -A "$user_agent" "${header_args[@]}" "$url" | grep -q "200 OK"; then
        echo -e "${GREEN}$url is reachable.${NC}"
        check_backups "$url"
        # After checking backups in the root path, run feroxbuster if enabled
        if [[ "$run_feroxbuster" -eq 1 ]]; then
            run_feroxbuster "$url"
        fi
    else
        echo -e "${RED}$url is not reachable.${NC}"
        log_error "Failed to connect to $url."
    fi
}

check_backups() {
    local base_url=$1
    shift
    local directories=("$@")  # Directories to scan; default is root "/"
    if [ ${#directories[@]} -eq 0 ]; then
        directories=("/")  # Default to root if no directories provided
    fi

    local base_names=($(generate_base_names "$base_url"))

    # Read extensions from wordlist
    local backup_extensions=()
    if [[ -f "$extensions_wordlist" ]]; then
        while IFS= read -r line; do
            backup_extensions+=("$line")
        done < "$extensions_wordlist"
    else
        # Default extensions if wordlist not found
        backup_extensions=("zip" "tar" "gz" "bz2" "7z" "sql" "bak" "tgz" "tbz" "dump")
    fi

    declare -A checked_urls

    for dir in "${directories[@]}"; do
        # Ensure directory starts and ends with a single '/'
        dir="/${dir#/}"
        dir="${dir%/}/"

        for base_name in "${base_names[@]}"; do
            for ext in "${backup_extensions[@]}"; do
                local file_url="${base_url}${dir}${base_name}.${ext}"

                # Check if the URL has already been checked
                if [[ -z "${checked_urls[$file_url]}" ]]; then
                    checked_urls["$file_url"]=1

                    if [ "$max_concurrent_jobs" -gt 1 ]; then
                        # Run in background if more than one thread is allowed
                        {
                            process_backup "$file_url"
                        } &
                        # Control the number of concurrent backup checks
                        job_control "$max_concurrent_jobs"
                    else
                        # Run synchronously if only one thread
                        process_backup "$file_url"
                    fi
                else
                    # URL has already been checked
                    echo -e "${YELLOW}Skipping already checked URL: $file_url${NC}"
                fi
            done
        done
    done

    # Wait for all background jobs in this function to finish
    wait
}

process_backup() {
    local file_url=$1
    local retries=0

    if [ "$verbosity" -ge 1 ]; then
        echo -e "${YELLOW}Checking for file: $file_url${NC}"
    fi

    # Prepare custom headers for curl
    local header_args=()
    for header in "${custom_headers[@]}"; do
        header_args+=("-H" "$header")
    done

    # Apply WAF bypass techniques if enabled
    if [[ "$waf_bypass" -eq 1 ]]; then
        url_and_user_agent=$(waf_bypass_methods "$file_url")
        file_url=$(echo "$url_and_user_agent" | awk '{print $1}')
        user_agent=$(echo "$url_and_user_agent" | awk '{print $2}')
    else
        user_agent=$(get_random_user_agent)
    fi

    while [ $retries -lt "$max_retries" ]; do
        # Fetch headers including status code and content type with timeout
        response=$(curl -s --head --max-time 10 --write-out "%{http_code}" --insecure -A "$user_agent" "${header_args[@]}" "$file_url")
        http_status="${response:(-3)}"
        headers="${response%$http_status}"

        if [[ "$http_status" == "200" ]]; then
            # Extract Content-Type
            content_type=$(echo "$headers" | grep -i "Content-Type:" | awk '{print $2}' | tr -d '\r')
            file_size=$(curl -sI --insecure -A "$user_agent" "${header_args[@]}" "$file_url" | grep -i "Content-Length" | awk '{print $2}' | tr -d '\r')

            if [[ " ${acceptable_types[@]} " =~ " ${content_type} " ]]; then
                echo -e "${GREEN}File found: $file_url [Content-Type: $content_type] [Size: ${file_size} bytes]${NC}" | tee -a "$output_file"
            else
                if [ "$verbosity" -ge 1 ]; then
                    echo -e "${RED}File at $file_url has unexpected Content-Type: $content_type${NC}"
                fi
            fi

            # Decrease delay on success
            if (( $(echo "$current_delay > $initial_delay" | bc -l) )); then
                current_delay=$(echo "$current_delay - $delay_decrement" | bc)
                if (( $(echo "$current_delay < $initial_delay" | bc -l) )); then
                    current_delay=$initial_delay
                fi
                if [ "$verbosity" -ge 1 ]; then
                    echo -e "${YELLOW}Decreasing delay to $current_delay seconds.${NC}"
                fi
            fi
            return  # Success, exit loop

        elif [[ "$http_status" == "429" ]] || [[ "$http_status" == 5* ]]; then
            if [ "$verbosity" -ge 1 ]; then
                echo -e "${RED}Received HTTP status $http_status from $file_url. Retrying...${NC}"
            fi
            ((retries++))
            # Increase delay on error
            current_delay=$(echo "$current_delay + $delay_increment" | bc)
            if (( $(echo "$current_delay > $max_delay" | bc -l) )); then
                current_delay=$max_delay
            fi
            if [ "$verbosity" -ge 1 ]; then
                echo -e "${YELLOW}Increasing delay to $current_delay seconds.${NC}"
            fi
            sleep "$current_delay"  # Introduce a small delay before retrying
        else
            if [ "$verbosity" -ge 1 ]; then
                echo -e "${RED}HTTP status $http_status for $file_url. Skipping.${NC}"
            fi
            return
        fi
    done

    if [ "$verbosity" -ge 1 ]; then
        echo -e "${RED}Failed to retrieve $file_url after $max_retries attempts.${NC}"
    fi
    log_error "Failed to retrieve $file_url after $max_retries attempts."
}

# Cloud-Based Backup Detection
check_cloud_backups() {
    local domain=$1
    echo -e "${YELLOW}Scanning for cloud-based backups on ${BLUE}$domain${NC}..."

    # AWS S3 Public Buckets (Example URL Patterns)
    echo -e "${MAGENTA}Checking AWS S3...${NC}"
    for s3_pattern in "https://$domain.s3.amazonaws.com" "https://s3.$domain.amazonaws.com" "https://s3.amazonaws.com/$domain"; do
        if curl -s --head "$s3_pattern" | grep -q "200 OK"; then
            echo -e "${GREEN}AWS S3 bucket found: $s3_pattern${NC}"
            echo "$s3_pattern" >> "$output_file"
        else
            echo -e "${RED}No public AWS S3 bucket detected at $s3_pattern.${NC}"
        fi
    done

    # Google Cloud Storage (GCS) Public Buckets
    echo -e "${MAGENTA}Checking Google Cloud Storage...${NC}"
    for gcs_pattern in "https://storage.googleapis.com/$domain" "https://$domain.storage.googleapis.com"; do
        if curl -s --head "$gcs_pattern" | grep -q "200 OK"; then
            echo -e "${GREEN}Google Cloud Storage bucket found: $gcs_pattern${NC}"
            echo "$gcs_pattern" >> "$output_file"
        else
            echo -e "${RED}No public GCS bucket detected at $gcs_pattern.${NC}"
        fi
    done

    # Azure Blob Storage Public Containers
    echo -e "${MAGENTA}Checking Azure Blob Storage...${NC}"
    for azure_pattern in "https://$domain.blob.core.windows.net" "https://$domain.file.core.windows.net"; do
        if curl -s --head "$azure_pattern" | grep -q "200 OK"; then
            echo -e "${GREEN}Azure Blob Storage container found: $azure_pattern${NC}"
            echo "$azure_pattern" >> "$output_file"
        else
            echo -e "${RED}No public Azure Blob detected at $azure_pattern.${NC}"
        fi
    done

    # DigitalOcean Spaces Public Buckets
    echo -e "${MAGENTA}Checking DigitalOcean Spaces...${NC}"
    for do_pattern in "https://$domain.nyc3.digitaloceanspaces.com" "https://$domain.ams3.digitaloceanspaces.com"; do
        if curl -s --head "$do_pattern" | grep -q "200 OK"; then
            echo -e "${GREEN}DigitalOcean Space bucket found: $do_pattern${NC}"
            echo "$do_pattern" >> "$output_file"
        else
            echo -e "${RED}No public DigitalOcean Space detected at $do_pattern.${NC}"
        fi
    done

    echo -e "${BLUE}Cloud-based backup scan completed for $domain.${NC}"
}

# Function to manage concurrent jobs
job_control() {
    local max_jobs=$1
    local current_jobs

    while true; do
        current_jobs=$(jobs -rp | wc -l)
        if [ "$current_jobs" -lt "$max_jobs" ]; then
            break
        fi
        sleep 0.1
    done
}

# Function to handle script termination and cleanup
cleanup() {
    echo -e "\n${RED}Script interrupted. Terminating all background processes...${NC}"
    # Kill all background jobs
    pkill -P $$
    wait
    echo -e "${RED}All background processes terminated. Exiting.${NC}"
    exit 1
}

# Trap SIGINT (Ctrl+C) and call cleanup function
trap cleanup SIGINT

# Check if curl is installed
if ! command -v curl &>/dev/null; then
    echo -e "${RED}Error: curl is not installed. Please install curl and try again.${NC}"
    exit 1
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -u|--url)
            input="$2"
            shift 2
            ;;
        -o|--output)
            output_file="$2"
            shift 2
            ;;
        -t|--threads)
            max_concurrent_jobs="$2"
            shift 2
            ;;
        -r|--retries)
            max_retries="$2"
            shift 2
            ;;
        -d|--delay)
            current_delay="$2"
            shift 2
            ;;
        -m|--max-delay)
            max_delay="$2"
            shift 2
            ;;
        -H|--header)
            custom_headers+=("$2")
            shift 2
            ;;
        -f|--feroxbuster)
            run_feroxbuster=1
            shift
            ;;
        -fw|--feroxbuster-wordlist)
            feroxbuster_wordlist="$2"
            shift 2
            ;;
        -v|--verbose)
            ((verbosity++))  # Increment verbosity level
            shift
            ;;
        -vv)
            verbosity=2  # Set verbosity to very verbose
            shift
            ;;
        -s|--subdomains)
            run_subdomain_scan=1
            shift
            ;;
        -y|--year)
            year="$2"
            shift 2
            ;;
        -b|--month)
            month="$2"
            shift 2
            ;;
        -w|--waf-bypass)
            waf_bypass=1
            shift
            ;;
        -c|--cloud)
            cloud_scan=1
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done


# Check if input is provided
if [ -z "$input" ]; then
    echo -e "${RED}Usage: $0 -u <Domain Name> [-o <output file>] [-t <threads>] [-r <retries>] [-d <initial delay>] [-m <max delay>] [-H <header>] [-f] [-fw <feroxbuster wordlist>] [-v] [-s] --year YYYY --month MM [-w] [-c]${NC}"
    exit 1
fi

# Validate max_concurrent_jobs
if ! [[ "$max_concurrent_jobs" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}Invalid number of threads specified. Please provide a positive integer.${NC}"
    exit 1
fi

# Subdomain scanning option
if [ "$run_subdomain_scan" -eq 1 ]; then
    echo -e "${YELLOW}Running subparrots.sh for subdomain scanning...${NC}"
    ./subparrots.sh "$input" "$output_file" "$max_concurrent_jobs"
fi

# Remove protocol and 'www.' from the input domain
input_domain=${input#*//}
input_domain=${input_domain#www.}

# Clear output file if it exists
> "$output_file"

# Scan the main domain immediately
for protocol in "http://" "https://"; do
    url="${protocol}${input_domain}"
    echo -e "${YELLOW}Scanning: $url${NC}"

    if [ "$max_concurrent_jobs" -gt 1 ]; then
        # Run in background if more than one thread is allowed
        check_connectivity "$url" &
        # Control the number of concurrent scans
        job_control "$max_concurrent_jobs"
    else
        # Run synchronously if only one thread
        check_connectivity "$url"
    fi
done

# Perform cloud-based backup scan if the -c flag is used
if [[ "$cloud_scan" -eq 1 ]]; then
    check_cloud_backups "$input_domain"
fi

# Wait for all background jobs to finish
wait

# Check if the output file is empty or not
if [[ -s "$output_file" ]]; then
    echo -e "${GREEN}File(s) found. Results written to $output_file.${NC}"
else
    echo -e "${RED}No files found. Results written to $output_file.${NC}"
fi
