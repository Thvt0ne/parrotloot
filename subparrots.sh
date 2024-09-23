#!/bin/bash

# Function to enumerate subdomains
enumerate_subdomains() {
    local domain=$1
    local subdomains=()

    # Remove protocol and 'www.' from the domain
    domain=${domain#*//}
    domain=${domain#www.}

    # Echo statements should go to stderr
    echo -e "${YELLOW}Enumerating subdomains for: $domain${NC}" >&2

    # Method 1: Using crt.sh API with timeout
    crtsh_data=$(curl -s --max-time 10 "https://crt.sh/?q=%25.$domain&output=json")
    if [[ $? -eq 0 && -n "$crtsh_data" ]]; then
        crtsh_subdomains=$(echo "$crtsh_data" | jq -r '.[].name_value' 2>/dev/null | sed 's/\*\.//g' | sort -u)
        subdomains+=($crtsh_subdomains)
    else
        echo -e "${RED}Failed to retrieve data from crt.sh or no data returned.${NC}" >&2
    fi

    # Method 2: Using Subfinder (if installed)
    if command -v subfinder &>/dev/null; then
        echo -e "${YELLOW}Running subfinder...${NC}" >&2
        subfinder_data=$(subfinder -silent -d "$domain")
        if [[ $? -eq 0 && -n "$subfinder_data" ]]; then
            subdomains+=($subfinder_data)
        else
            echo -e "${RED}Subfinder did not return any data.${NC}" >&2
        fi
    fi

    # Method 3: Using amass (if installed)
    if command -v amass &>/dev/null; then
        echo -e "${YELLOW}Running amass...${NC}" >&2
        amass_data=$(amass enum -passive -d "$domain" 2>/dev/null)
        if [[ $? -eq 0 && -n "$amass_data" ]]; then
            subdomains+=($amass_data)
        else
            echo -e "${RED}Amass did not return any data.${NC}" >&2
        fi
    fi

    # Remove duplicates
    if [[ ${#subdomains[@]} -gt 0 ]]; then
        subdomains=($(printf "%s\n" "${subdomains[@]}" | sort -u))
        # Only output the subdomains
        printf "%s\n" "${subdomains[@]}"
    else
        echo -e "${YELLOW}No subdomains found.${NC}" >&2
    fi
}

# Function to check connectivity and scan subdomains for backups
check_connectivity_subdomain() {
    local url=$1
    local user_agent=$(get_random_user_agent)

    if curl -s --head --insecure -A "$user_agent" "$url" | grep -q "200 OK"; then
        echo -e "${GREEN}$url is reachable.${NC}"
        check_backups "$url"
    else
        echo -e "${RED}$url is not reachable.${NC}"
    fi
}

# Parse the arguments
domain=$1
output_file=$2
max_concurrent_jobs=$3

# Enumerate subdomains
subdomains_file=$(mktemp)
enumerate_subdomains "$domain" > "$subdomains_file"
mapfile -t subdomains < "$subdomains_file"
rm "$subdomains_file"  # Clean up the temporary file

# Remove the main domain from the subdomains list if present
subdomains=("${subdomains[@]/$domain}")

# Check if there are subdomains found
if [ ${#subdomains[@]} -gt 0 ]; then
    echo -e "${YELLOW}Subdomains found:${NC}"
    for sub in "${subdomains[@]}"; do
        echo -e "${GREEN}- $sub${NC}"
    done

    # Scan each subdomain
    for subdomain in "${subdomains[@]}"; do
        for protocol in "http://" "https://"; do
            url="${protocol}${subdomain}"
            echo -e "${YELLOW}Scanning: $url${NC}"

            if [ "$max_concurrent_jobs" -gt 1 ]; then
                # Run in background if more than one thread is allowed
                check_connectivity_subdomain "$url" &
                # Control the number of concurrent scans
                job_control "$max_concurrent_jobs"
            else
                # Run synchronously if only one thread
                check_connectivity_subdomain "$url"
            fi
        done
    done

    # Wait for all background jobs to finish
    wait
else
    echo -e "${YELLOW}No subdomains found to scan.${NC}"
fi
