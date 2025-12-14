
#!/bin/bash

echo ""
echo "Author: Ahmed Fawzy (Github: amf95)"
echo ""

# Target: linux-amd64 with systemd.

# This script automates the installation of Prometheus on Linux systems.


####################################################################################

# Features and Usage:

# Allow user to choose port during installation (default is 9090).

# Install Prometheus latest version from GitHub releases or a specific version:
# bash ./install-prometheus.sh

# Install from a local tar.gz file provided by the user:
# Note: The local file must match the pattern 'prometheus-X.Y.Z.linux-amd64.tar.gz'.
# bash ./install-prometheus.sh --local prometheus-3.7.3.linux-amd64.tar.gz

# Uninstall Prometheus while keeping data:
# Note: The script offers to backup existing installation before uninstalling.
# bash ./install-prometheus.sh --uninstall

# Purge Prometheus installation and all data:
# Note: The script offers to backup existing installation before purge.
# bash ./install-prometheus.sh --purge

####################################################################################


#===================================================================================
#                             Script Safety and Setup
#===================================================================================

#=================== Script Safety Settings =====================
# Enable strict error handling
set -euo pipefail

#=================== IFS Setting ====================
# Set Internal Field Separator to handle spaces in filenames
IFS=$'\n\t'

#=================== Colorized Output Setup ====================
# Check if output is a terminal to enable colors
if [ -t 1 ]; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    MAGENTA=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    BOLD=$(tput bold)
    RESET=$(tput sgr0)
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    MAGENTA=""
    CYAN=""
    BOLD=""
    RESET=""
fi

#===================================================================================
#                        End of Script Safety and Setup
#===================================================================================


#===================================================================================
#                             Helping Functions Section
#===================================================================================

#=================== Colorized Output Functions ====================
# Purpose: Standardize colored output for different message types
info()    { echo -e "${BLUE}${BOLD}[INFO]${RESET} $*"; }
success() { echo -e "${GREEN}${BOLD}[OK]${RESET} $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[WARN]${RESET} $*"; }
error()   { echo -e "${RED}${BOLD}[ERROR]${RESET} $*" >&2; }

#=================== Backup Old Installation Function ====================
# Function: backup_old_installation
# Purpose: Backs up existing Prometheus installation if it exists
# Prompts user for confirmation before creating backup
backup_old_installation() {
    if [ -d "/opt/monitoring/prometheus" ]; then
        warn "Existing Prometheus installation detected." >&2
        local confirm_backup==""
        read -p "would you like to backup old installation? [Y/n]: " confirm_backup # -n 1 -r
        echo "" >&2
        if [[ "$confirm_backup" =~ ^[Nn]$ ]]; then
            warn "Continuing without backup." >&2
            return 0
        fi

        local backup_name="prometheus_backup_$(date +%Y.%m.%d_%H-%M-%S)"
        warn "Creating backup of existing installation to /opt/monitoring/$backup_name ..." >&2
        # tar:
        # '-C': change to directory temporarily before performing operations
        if ! tar -czf "/opt/monitoring/$backup_name.tar.gz" -C /opt/monitoring prometheus; then
            error "Failed to create backup" >&2
            exit 1
        fi
        success "Backup created at /opt/monitoring/$backup_name.tar.gz" >&2
    fi # End of: if /opt/monitoring/prometheus exists
} # end of: backup_old_installation function


#=================== Remove Old Installation Function ====================
# Function: remove_old_installation
# Purpose: Removes existing Prometheus installation based on user choice
# Parameters:
#   $1 (action): "purge" to remove all data and configs, "uninstall" to remove binaries only
# Returns: "success", "not_installed", "cancelled", or "not_found"
remove_old_installation() {
    # Check if argument is provided
    if [ -z "$1" ]; then
        error "remove_old_installation requires an argument: 'purge' or 'uninstall'"  >&2
        echo "failed"
        exit 1
    fi

    warn "Removing old Prometheus installation..."  >&2

    if ! [ -d /opt/monitoring/prometheus ]; then
        echo "not_installed"
        return
    fi

    # Stop and disable service if active
    if systemctl status prometheus >/dev/null 2>&1; then
        info "Prometheus service detected. Stopping and disabling..."  >&2
        systemctl stop prometheus || warn "Failed to stop Prometheus service." >&2
        systemctl disable prometheus || warn "Failed to disable Prometheus service." >&2
        pkill -u prometheus 2>/dev/null || true
        pkill -f "/opt/monitoring/prometheus/prometheus" 2>/dev/null || true
    fi

    if [ "$1" == "purge" ]; then
        if [ -d /opt/monitoring/prometheus/data ]; then
            warn "[/opt/monitoring/prometheus/data] detected. Do you want to purge all data?"  >&2
            warn "This action is irreversible and will delete all Prometheus [data] and [configs]."  >&2
            local confirm_purge=""
            read -p "Continue with purge? [y/N]: " -n 1 -r
            echo "" >&2
            if [[ ! "$confirm_purge" =~ ^[Yy]$ ]]; then
                echo "cancelled"
                return
            fi
            backup_old_installation
            rm -rf /opt/monitoring/prometheus
            userdel prometheus || warn "Failed to delete prometheus user." >&2
        fi # End of: if data directory exists 
    elif [ "$1" == "uninstall" ]; then
        warn "[Prometheus binary], [promtool] and [prometheus.service] will be removed."  >&2
        local confirm_uninstall=""
        read -p "Would you like to continue? [y/N]: " confirm_uninstall # -n 1 -r
        echo "" >&2
        if [[ ! "$confirm_uninstall" =~ ^[Yy]$ ]]; then
            echo "cancelled"
            return
        fi
        if ! [ -f /opt/monitoring/prometheus/prometheus ]; then
            echo "not_found" 
            return 
        fi
        backup_old_installation
        # remove only binaries and service, keep data
        rm -f /opt/monitoring/prometheus/prometheus
        rm -f /opt/monitoring/prometheus/promtool
    fi # End of: if purge or uninstall
    
    info "Removing service files and symlinks..."  >&2
    # Remove symlinks and service file
    rm -f /usr/local/bin/prometheus
    rm -f /usr/local/bin/promtool
    rm -f /etc/systemd/system/prometheus.service

    # Reload systemd daemon to clear removed service
    systemctl daemon-reload || true
    echo "success"
    return
    # Remove Prometheus system user
    # if id prometheus &>/dev/null; then
    #     userdel prometheus || warn "Failed to delete prometheus user."
    # fi
} # end of: remove_old_installation function


#=================== Version Detection Function ====================
# Function: get_current_version
# Purpose: Detects the currently installed Prometheus version
# Parameters: None
# Returns: Current version string or "not_installed"
get_current_version() {
    # check if prometheus command exists and is executable then redirect errors/output(2>&1) to /dev/null.
    if command -v prometheus >/dev/null 2>&1; then
        # Extract version number from prometheus --version output.
        local current_version=$(prometheus --version 2>&1 | head -n 1 |grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
        # return the current version
        echo "$current_version"
        return
    fi
    # If not installed, return "not_installed"
    echo "not_installed"
    return
} # end of: get_current_version function


#=================== Download and Verification Functions ====================
# Function: download_from_url
# Purpose: Downloads a file from a given URL using curl
# Parameters:
#   $1 (download_url): URL to download from
#   $2 (output_file_name): Name of the output file
# Returns: "success" or "failed"
download_from_url() {
    local download_url="$1"
    local output_file_name="$2"

    # Check if curl is available
    if command -v curl >/dev/null 2>&1; then
        # curl options:
        #   -L: follow redirects
        #   -o: output to file
        info "Downloading $output_file_name ..." >&2
        curl --progress-bar -L -o "$output_file_name" "$download_url"
        success "Downloaded $output_file_name successfully." >&2
        echo "success"
        return
    else
        error "curl is not installed. Please install curl and re-run the script." >&2
        echo "failed"
        return
    fi
} # end of: download function


#=================== Checksum Verification Functions ====================
# Function: verify_checksum
# Purpose: Verifies the SHA256 checksum of a downloaded file
# Parameters:
#   $1 (prometheus_compressed_file): Name of the downloaded file 
#   $2 (checksum_file): Name of the checksum file
# Returns: "success", "failed", or "not_found"
verify_checksum() {
    local prometheus_compressed_file="$1"
    local checksum_file="$2"

    info "Verifying checksum for $prometheus_compressed_file" >&2

    if [ ! -s "$checksum_file" ]; then
        error "Checksum file missing or empty." >&2
        echo "not_found"
        return
    fi

    # Extract relevant checksum line
    grep -E "(^| )${prometheus_compressed_file}\$" "$checksum_file" > /tmp/sum.txt

    if [ ! -s /tmp/sum.txt ]; then
        error "Checksum for $prometheus_compressed_file not found in $checksum_file" >&2
        rm -f /tmp/sum.txt
        echo "not_found"
        return
    fi

    # Verify checksum using sha256sum
    if sha256sum --check /tmp/sum.txt --status; then
        rm -f /tmp/sum.txt
        echo "success"
        return
    else
        rm -f /tmp/sum.txt
        echo "failed"
        return
    fi
} # end of: verify_checksum function


#=================== Port Input Function ====================
# Function: get_port_from_user
# Purpose: Prompts user for custom port input with validation
# Parameters: None
# Returns:  Valid port number (default 9090 if none provided)
get_port_from_user(){
    local port=""
    read -p "Enter custom port between 2000 and 65535 or press Enter for [default: 9090]: " port
    echo "" >&2
    if [ -z "$port" ]; then
        echo -n "9090"
        return
    # check if port is a number and within valid range
    elif [[ "$port" =~ ^[0-9]+$ ]] && (( port >= 2000 && port <= 65535 )); then
        echo -n "$port"
        return
    else
        error "Invalid port number." >&2
        get_port_from_user
    fi
} # end of: get_port_from_user function

#=================== Requirements Check Function ====================
# Function: check_requirements
# Purpose: Ensures script is run with root privileges and required 
# dependencies are installed
# Parameters:
#   $1 (installation_method): Installation method ("github" or "local")
# Returns: None 
check_requirements(){
    local installation_method="$1"

    #=================== Root Privilege Check ====================
    if [ "$EUID" -ne 0 ]; then
    error "Please run as root or with sudo." >&2
    exit 1
    fi

    #=================== Dependency Check ====================
    # Purpose: Ensure required commands are available
    info "Checking for required dependencies..."
    for cmd in tar systemctl; do
        command -v "$cmd" >/dev/null 2>&1 || { error "$cmd not installed"; exit 1; }
    done

    if [ "$installation_method" == "github" ]; then
        for cmd in curl jq sha256sum; do
            command -v "$cmd" >/dev/null 2>&1 || { error "$cmd not installed"; exit 1; }
        done
    fi

    success "All dependencies are installed." >&2
} # end of: check_requirements function

#=================== Version Comparison Function ====================
# Function: compare_versions
# Purpose: Compares current and target Prometheus versions and prompts
# for reinstallation if they match
# Parameters:
#   $1 (current_version): Currently installed version
#   $2 (version_to_install): Version intended for installation
# Returns: None
compare_versions() {
    local current_version="$1"
    local version_to_install="$2"
    #=================== Version Check and Confirmation ====================
    if [ "$current_version" != "not_installed" ]; then
        if [ "$current_version" == "$version_to_install" ]; then
            warn "You already have version ($current_version) installed." >&2
            # Prompt user for reinstallation confirmation
            local confirm_reinstall=""
            read -p "Do you want to reinstall? [y/N]: " confirm_reinstall # -n 1 -r
            echo "" >&2
            if [[ ! "$confirm_reinstall" =~ ^[Yy]$ ]]; then
                # exit if answer is not 'y' or 'Y' 
                info "Exiting without reinstallation." >&2
                exit 0
            fi
        fi # End of: if CURRENT_VERSION == VERSION_TO_INSTALL
    fi # End of: if CURRENT_VERSION != "not_installed"
} # end of: compare_versions function

#####################################################################################
#                       End of Helpins" ]; g Functions Section
####################################################################################



####################################################################################
#                                 Start of Script
####################################################################################

# default installation method is from github
INSTALLATION_METHOD="github"

# if current version is not installed, it will return "not_installed"
CURRENT_VERSION=$(get_current_version)

CHECKSUM_FILE_NAME="sha256sums.txt"

####################################################################################
#                              Argument Parsing Section
####################################################################################

# Usage: bash ./install-prometheus.sh --help
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "Usage: bash ./$0 [--purge | --uninstall | --local FILE]"
    exit 0
# ================== Purge Installation ====================
# Usage: bash  ./install-prometheus.sh --purge
elif [[ "${1:-}" == "--purge" || "${1:-}" == "-p" ]]; then
    # delete all data and uninstall
    purge_result=$(remove_old_installation "purge")
    info "Removale function returned: $purge_result"
    if [ "$purge_result" == "not_installed" ]; then
        error "No existing Prometheus installation found."
        exit 0
    elif [ "$purge_result" == "cancelled" ]; then
        warn "Purge cancelled by user."
        exit 0
    elif [ "$purge_result" == "success" ]; then
        success "Prometheus purged successfully."
        exit 0
    else
        error "Purge failed."
        exit 1
    fi
# ================== Uninstall Installation ====================
# Usage: bash  ./install-prometheus.sh --uninstall
elif [[ "${1:-}" == "--uninstall" || "${1:-}" == "-u" ]]; then
    # just uninstall but keep data
    uninstall_result=$(remove_old_installation "uninstall")

    info "Removale function returned: $uninstall_result"
    if [ "$uninstall_result" == "not_installed" ]; then
        error "No existing Prometheus installation found."
        exit 0
    elif [ "$uninstall_result" == "cancelled" ]; then
        warn "Uninstallation cancelled by user."
        exit 0
    elif [ "$uninstall_result" == "not_found" ]; then
        error "Prometheus binary not found in installation directory."
        exit 0
    elif [ "$uninstall_result" == "success" ]; then
        success "Prometheus uninstalled successfully."
        exit 0
    else
        error "Uninstallation failed."
        exit 1
    fi
# ================== Local Installation ====================
# Usage: bash ./install-prometheus.sh -l prometheus-3.7.3.linux-amd64.tar.gz
elif [[ "${1:-}" == "--local" || "${1:-}" == "-l" ]]; then
    # local installation from specified file
     
    # check if file argument is provided
    if [ -z "${2:-}" ]; then
        error "No file specified for the local installation."
        exit 1
    fi

    LOCAL_FILE_FULL_PATH="${2:-}"

    PROMETHEUS_COMPRESSED_FILE=$(basename "$LOCAL_FILE_FULL_PATH")

    # Check if the PROMETHEUS_COMPRESSED_FILE matches the pattern
    if ! [[ "$PROMETHEUS_COMPRESSED_FILE" =~ ^prometheus-[0-9]+\.[0-9]+\.[0-9]+\.linux-amd64\.tar\.gz$ ]]; then
        error "$PROMETHEUS_COMPRESSED_FILE does not match the Prometheus tarball pattern."
        exit 1
    fi

    PROMETHEUS_EXTRACTED_FOLDER=$(echo "$PROMETHEUS_COMPRESSED_FILE" | awk -F '.tar.gz' '{print $1}')
    VERSION_TO_INSTALL=$(echo "$PROMETHEUS_EXTRACTED_FOLDER" | sed -E 's/.*prometheus-([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
    info "Current Version: $CURRENT_VERSION"
    info "Version To Install: $VERSION_TO_INSTALL"
    compare_versions "$CURRENT_VERSION" "$VERSION_TO_INSTALL"
    INSTALLATION_METHOD="local"
elif [[ -n "${1:-}" ]]; then
    error "Invalid argument. Use --help for usage information."
    exit 1
fi


#=================== Check Requirements ====================
check_requirements "$INSTALLATION_METHOD"


#=================== Get Port From User ====================
PORT=$(get_port_from_user)
info "Using port: $PORT"
# Check if port is already in use
if ss -tuln | grep -E "(:$PORT\s|:$PORT$)">/dev/null 2>&1; then
    warn "Port $PORT is already in use."
    echo "" >&2
    CONFIRM_PPORT_BYPASS=""
    read -p "Continue anyway? [y/N]: " CONFIRM_PPORT_BYPASS # -n 1 -r
    echo "" >&2
    [[ "$CONFIRM_PPORT_BYPASS" =~ ^[Yy]$ ]] || exit 1
fi

if [ "$INSTALLATION_METHOD" == "github" ]; then
    OLD_DIR=$(pwd)
    # Change directory temporarily
    cd /tmp || exit
    #=================== Clean Downloaded Files On Exit ====================
    #trap 'rm -rf "./${PROMETHEUS_COMPRESSED_FILE:-}" "./${PROMETHEUS_EXTRACTED_FOLDER:-}" CHECKSUM_FILE_NAME response.json 2>/dev/null' EXIT
    #trap 'rm -rf CHECKSUM_FILE_NAME response.json 2>/dev/null' EXIT
    trap 'cd "$OLD_DIR"' EXIT

    #=================== Github Connectivity Check ====================
    info "Checking Github connectivity..."

    if curl -s --head "https://github.com" >/dev/null; then
        success "GitHub is reachable!"
    else
        error "GitHub is not reachable. Check your internet connection!"
        exit 1
    fi

    #=================== User Version Selection ====================
    SELECTED_VERSION=""
    echo ""
    read -p "Enter version (EXP: 3.7.0) or press Enter for [latest]: " SELECTED_VERSION
    echo ""

    # if SELECTED_VERSION is empty, proceed to install latest version  
    if [ -z "$SELECTED_VERSION" ]; then
        #=================== Get Latest Version ====================
        LATEST_PROMETHEUS_GITHUB_URL=https://api.github.com/repos/prometheus/prometheus/releases/latest

        info "Fetching latest Prometheus release info from GitHub API..."
        info "LATEST_PROMETHEUS_GITHUB_URL: $LATEST_PROMETHEUS_GITHUB_URL"

        HTTP_CODE=$(curl -s -o response.json -w "%{http_code}" "$LATEST_PROMETHEUS_GITHUB_URL")
        RESPONSE_BODY=$(<response.json)

        info "Github response code: $HTTP_CODE"

        if [ "$HTTP_CODE" != "200" ]; then
            error "Failed to fetch latest version from GitHub. HTTP Status: $HTTP_CODE"
            # warn "Response: $RESPONSE_BODY"
            exit 1
        fi

        PROMETHEUS_DOWNLOAD_URL=$(echo "$RESPONSE_BODY" | jq -r '.assets[] | select(.name | test("linux-amd64.tar.gz$")) | .browser_download_url')

        if [ -z "$PROMETHEUS_DOWNLOAD_URL" ]; then
            error "Could not find download URL for linux-amd64 in GitHub response"
            exit 1
        fi

        PROMETHEUS_COMPRESSED_FILE=$(echo "$PROMETHEUS_DOWNLOAD_URL" | awk -F '/' '{print $NF}')
        PROMETHEUS_EXTRACTED_FOLDER=$(echo "$PROMETHEUS_COMPRESSED_FILE" | awk -F '.tar.gz' '{print $1}')
        VERSION_TO_INSTALL=$(echo "$PROMETHEUS_EXTRACTED_FOLDER" | sed -E 's/.*prometheus-([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
        CHECKSUM_DOWNLOAD_URL="https://github.com/prometheus/prometheus/releases/download/v${VERSION_TO_INSTALL}/${CHECKSUM_FILE_NAME}"
    else
        #=================== Specific Version Mode ====================
        info "Checking availability of Prometheus version v${SELECTED_VERSION}..."
        PROMETHEUS_DOWNLOAD_URL="https://github.com/prometheus/prometheus/releases/download/v${SELECTED_VERSION}/prometheus-${SELECTED_VERSION}.linux-amd64.tar.gz"

        # Verify if the specific version exists by checking the URL
        if curl -sfI "$PROMETHEUS_DOWNLOAD_URL" >/dev/null 2>&1; then
            success "Version v${SELECTED_VERSION} found."
            VERSION_TO_INSTALL="$SELECTED_VERSION"
            PROMETHEUS_COMPRESSED_FILE="prometheus-${SELECTED_VERSION}.linux-amd64.tar.gz"
            PROMETHEUS_EXTRACTED_FOLDER="prometheus-${SELECTED_VERSION}.linux-amd64"
            CHECKSUM_DOWNLOAD_URL="https://github.com/prometheus/prometheus/releases/download/v${SELECTED_VERSION}/${CHECKSUM_FILE_NAME}"
        else
            error "Version v${SELECTED_VERSION} not found on GitHub."
            exit 1
        fi
    fi # End of: if SELECTED_VERSION is empty

    #=================== Display Summary ====================
    info "Download URL: $PROMETHEUS_DOWNLOAD_URL"
    info "Checksum URL: $CHECKSUM_DOWNLOAD_URL"
    info "File to download: $PROMETHEUS_COMPRESSED_FILE"
    info "Folder to extract: $PROMETHEUS_EXTRACTED_FOLDER"
    info "Current Version: $CURRENT_VERSION"
    info "Version To Install: $VERSION_TO_INSTALL"


    compare_versions "$CURRENT_VERSION" "$VERSION_TO_INSTALL"


    #=================== Download and Verify Binary ====================
    # Check if .tar.gz file already exists, download prometheus and checksum if missing
    if [ ! -e "$PROMETHEUS_COMPRESSED_FILE" ]; then
        download_from_url "$PROMETHEUS_DOWNLOAD_URL" "$PROMETHEUS_COMPRESSED_FILE" 
    else
        info "$PROMETHEUS_COMPRESSED_FILE already exists"
    fi # End of: if file exists
    
#    if [ ! -e "$CHECKSUM_FILE_NAME" ]; then
    download_from_url "$CHECKSUM_DOWNLOAD_URL" "$CHECKSUM_FILE_NAME"
#    else
#        info "$CHECKSUM_FILE_NAME already exists"
#    fi # End of: if file exists

    # Verify checksum after download
    checksum_result=$(verify_checksum "$PROMETHEUS_COMPRESSED_FILE" "$CHECKSUM_FILE_NAME")
    if [ "$checksum_result" == "success" ]; then
        success "Checksum verification succeeded!"
    elif [ "$checksum_result" == "failed" ]; then
        warn "Removing corrupted [$PROMETHEUS_COMPRESSED_FILE] file..."
        rm -f "$PROMETHEUS_COMPRESSED_FILE" "$CHECKSUM_FILE_NAME"
        info "Please re-run the script to download again."
        exit 1
    elif [ "$checksum_result" == "not_found" ]; then
        error "Checksum verification file not found or invalid."
        warn "Removing [$CHECKSUM_FILE_NAME] file..."
        rm -f "$CHECKSUM_FILE_NAME"
        info "Please re-run the script to download again."
        exit 1
    fi # End of: if verify_checksum
fi # End of: if INSTALLATION_METHOD == "github"


# Clean up any existing extracted folder
if [ -e "$PROMETHEUS_EXTRACTED_FOLDER" ]; then
    rm -rf "$PROMETHEUS_EXTRACTED_FOLDER"
fi


#=================== Extract Archive ====================
# Extract downloaded archive if not already extracted
if [ ! -e "$PROMETHEUS_EXTRACTED_FOLDER" ]; then
    info "Extracting $PROMETHEUS_COMPRESSED_FILE ..."
    if [ "$INSTALLATION_METHOD" == "local" ]; then
        tar -zxf "$LOCAL_FILE_FULL_PATH"
    elif [ "$INSTALLATION_METHOD" == "github" ]; then
        tar -zxf "$PROMETHEUS_COMPRESSED_FILE"
    fi
    
else
    info "$PROMETHEUS_EXTRACTED_FOLDER already exists"
fi


#=================== Remove Old Installation ====================
# Remove old installation before proceeding with new installation
CLEANUP_RESULT=$(remove_old_installation "uninstall")
info "Removale function returned: $CLEANUP_RESULT"
if [ "$CLEANUP_RESULT" == "not_installed" ]; then
    warn "No existing Prometheus installation found."
elif [ "$CLEANUP_RESULT" == "cancelled" ]; then
    warn "Installation cancelled by user during cleanup."
    exit 0
fi


#===================================================================================
#                             Start of installation
#===================================================================================

info "Starting Prometheus installation..."

#=================== Directory Setup ====================
info "Creating necessary directories..."
# Create required directories with proper permissions
# install options:
#   -d: create directories
#   -m 0755: set permissions (rwxr-xr-x)
if ! [ -d /opt/monitoring ]; then
    install -d -m 0755 /opt/monitoring
fi
if ! [ -d /opt/monitoring/prometheus ]; then
    install -d -m 0755 /opt/monitoring/prometheus
fi
if ! [ -d /opt/monitoring/prometheus/log ]; then
    install -d -m 0755 /opt/monitoring/prometheus/log
fi
if ! [ -d /opt/monitoring/prometheus/data ]; then
    install -d -m 0755 /opt/monitoring/prometheus/data
fi


info "Moving Prometheus files to installation directory..."

# Copy Prometheus files to installation directory
#cp -r "$PROMETHEUS_EXTRACTED_FOLDER"/* /opt/monitoring/prometheus/
# Copy individual files to avoid overwriting existing prometheus.yml and override others
cp "$PROMETHEUS_EXTRACTED_FOLDER/LICENSE" /opt/monitoring/prometheus/
cp "$PROMETHEUS_EXTRACTED_FOLDER/NOTICE" /opt/monitoring/prometheus/
cp "$PROMETHEUS_EXTRACTED_FOLDER/prometheus" /opt/monitoring/prometheus/
cp "$PROMETHEUS_EXTRACTED_FOLDER/promtool" /opt/monitoring/prometheus/
# Protect existing prometheus.yml if it exists
if ! [ -f /opt/monitoring/prometheus/prometheus.yml ]; then
    cp "$PROMETHEUS_EXTRACTED_FOLDER/prometheus.yml" /opt/monitoring/prometheus/
fi


#=================== User and Permissions Setup ====================
info "Setting up prometheus user and permissions..."
# Create system user 'prometheus' if it doesn't exist
if ! id -u prometheus &>/dev/null; then
    useradd --system --no-create-home --shell /bin/false prometheus
fi


# Set proper ownership and permissions
chown -R prometheus:prometheus /opt/monitoring/prometheus


# Make binaries executable for prometheus user
chmod u+x /opt/monitoring/prometheus/prometheus
chmod u+x /opt/monitoring/prometheus/promtool


#=================== Create System-wide Links ====================
info "Creating system-wide symlinks in '/usr/local/bin' ..."
# Create symlinks in /usr/local/bin for system-wide access
ln -sf /opt/monitoring/prometheus/prometheus /usr/local/bin/prometheus
ln -sf /opt/monitoring/prometheus/promtool /usr/local/bin/promtool


# Set proper permissions for symlinked binaries
chmod 755 /usr/local/bin/prometheus /usr/local/bin/promtool

#=================== Log File Setup ====================
info "Setting up log file..."
touch /opt/monitoring/prometheus/log/error.log
chown prometheus:prometheus /opt/monitoring/prometheus/log/error.log
chmod 640 /opt/monitoring/prometheus/log/error.log

#===================================================================================
#                          Systemd Service Configuration
#===================================================================================
# Create systemd service file for Prometheus

# for older systemd versions that do not support 'StandardError=append:path'.
# < v240 (e.g., Ubuntu 18.04, CentOS 7)
# for newer systemd versions that support 'StandardError=append:path'.
# >= v240 (e.g., Ubuntu 20.04+, CentOS 8+)
SYSTEMD_VERSION=$(systemd-analyze --version 2>/dev/null | awk '/systemd/{print $2}')
# Default to 0 if empty
SYSTEMD_VERSION="${SYSTEMD_VERSION:-0}"

SYSTEMD_LOGGING="append:/opt/monitoring/prometheus/log/prometheus.log"

if [ "$SYSTEMD_VERSION" -gt 0 ] && [ "$SYSTEMD_VERSION" -le 240 ] 2>/dev/null; then
    SYSTEMD_LOGGING="journal"
fi

SYSTEMD_SERVICE_FILE="
[Unit]

Description=Prometheus stores metrics coming from it's exporters. Default Web_UI: http://localhost:$PORT

Wants=network-online.target

After=network-online.target

# wait x seconds between each time you try to restart on-failure.
StartLimitIntervalSec=30

# try to restart service x times on-failure
StartLimitBurst=3

[Service]

User=prometheus
Group=prometheus

Type=simple

ExecStart=/opt/monitoring/prometheus/prometheus \
--config.file=/opt/monitoring/prometheus/prometheus.yml \
--storage.tsdb.path=/opt/monitoring/prometheus/data \
--web.enable-lifecycle \
--log.level=warn \
--web.listen-address=:$PORT
#--storage.tsdb.retention.time=7d
#--storage.tsdb.retention.size=512MB

# prometheus only outputs to one log stream.
StandardOutput=$SYSTEMD_LOGGING
StandardError=inherit

Restart=on-failure

[Install]

WantedBy=multi-user.target
"
#----------------------------#
#----End Of .service File----#
#----------------------------#

info "Creating systemd service file at [/etc/systemd/system/prometheus.service] ..."

cat <<EOF > /etc/systemd/system/prometheus.service
$SYSTEMD_SERVICE_FILE
EOF

#===================================================================================
#                              Service Activation
#===================================================================================
info "Enabling and starting Prometheus service..."
systemctl daemon-reload
systemctl enable prometheus.service
systemctl start prometheus.service
systemctl status --no-pager prometheus.service


echo ""
success "Installation completed successfully!"

#===================================================================================
#                             Firewall Configuration
#===================================================================================
# Display instructions for configuring common firewalls
echo ""
info "To open ports in firewalld public zone run:"
echo "firewall-cmd --permanent --add-port=$PORT/tcp"
echo "firewall-cmd --reload"
echo ""
info "To open ports in UFW for everybody run:"
echo "ufw allow from any to any port $PORT proto tcp"
echo "ufw enable"

# Get the server's IP address for access instructions
IP=$(hostname -I | awk '{print $1}')
echo ""
info "For default web UI visit: http://$IP:$PORT"
echo ""

####################################################################################
#                                 End of Script
####################################################################################
