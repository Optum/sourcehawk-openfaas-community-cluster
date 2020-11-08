#!/bin/sh

set -e

###############################################################################
#
# This is the script copied into the docker image for the scan function.  It
# is essentially the entrypoint to the function
#
# Required Environment
# -----------------------
# GITHUB_API_URL: Github API URL
# GITHUB_ORG: Github Organization
# GITHUB_REPO: Github Repository
# GITHUB_REF: Github Ref, i.e - main, master, v1.3, 6faed2
# OUTPUT_FORMAT: Output Format of the scan
#
# Optional Environment
# -----------------------
# GITHUB_AUTH_TOKEN: Github authorization token if required for accessing repo
#
# Optional Standard Input (stdin)
# If the stdin is populated, use it as the scan configuration
#
# Exit Code Handling
# -----------------------
# By default exit codes are delegated to shell and commands.
#
# Custom Exit Codes
# -----------------------
# 61: Github Authorization Failure
# 64: Github Org / Repo / Ref Not Found
# 65: Error Downloading Source Code
# 66: Scan resulted in exit code (1)
# 67: Scan resulted in exit code (2)
# 68: Scan resulted in unknown error
#
###############################################################################

TEMP_DIR="/tmp/${GITHUB_ORG}-${GITHUB_REPO}-${GITHUB_REF}-$(date +%s%N | cut -b1-13)"
ZIP_FILE="$TEMP_DIR/source.zip"
SOURCE_CODE_EXTRACT_DIRECTORY="$TEMP_DIR/source"
PROVIDED_CONFIG_FILE="$TEMP_DIR/sourcehawk-provided.yml"
ERROR_OUTPUT_FILE="$TEMP_DIR/scan_error.txt"

error_and_exit() {
  echo "$2" > /dev/stderr
  exit "$1"
}

cleanup() {
  rm -rf "$TEMP_DIR"
}

trap cleanup INT EXIT

# Make the temp working directory
mkdir -p "$TEMP_DIR"

# Retrieve the provided config from stdin
# shellcheck disable=SC2162 disable=SC2039
#if read -t 0; then
#  cat > "$PROVIDED_CONFIG_FILE"
#fi

# Download a zip file of the repository contents
GITHUB_ZIPBALL_URL="$GITHUB_API_URL/repos/$GITHUB_ORG/$GITHUB_REPO/zipball/$GITHUB_REF"
DOWNLOAD_RESPONSE_INFO=$(wget -S --header="Authorization: token $GITHUB_AUTH_TOKEN" "$GITHUB_ZIPBALL_URL" -O "$ZIP_FILE" 2>&1 || error_and_exit 65 "Error downloading/writing zip file")
DOWNLOAD_RESPONSE_CODE=$(echo "$DOWNLOAD_RESPONSE_INFO" | grep "HTTP/" | tail -1 | awk '{ print $2 }')

if [ "$DOWNLOAD_RESPONSE_CODE" = 401 ]; then
  error_and_exit 61 "The authorization token provided is not valid or does not have proper access"
elif [ "$DOWNLOAD_RESPONSE_CODE" = 404 ]; then
  error_and_exit 64 "Could not find source code to scan.  Please make sure the token provided has proper access."
fi

# Unzip the source code tarball
mkdir -p "$SOURCE_CODE_EXTRACT_DIRECTORY" && unzip -qq -d "$SOURCE_CODE_EXTRACT_DIRECTORY" "$ZIP_FILE"

# Grab the repository root from unzipped tarball
# shellcheck disable=SC2035
SOURCE_CODE_ROOT_DIRECTORY=$(cd "$SOURCE_CODE_EXTRACT_DIRECTORY" && cd */. && pwd)

# Use the provided config file if present and not empty, otherwise default
CONFIG_FILE="${SOURCE_CODE_ROOT_DIRECTORY}/sourcehawk.yml"
if [ -f "$PROVIDED_CONFIG_FILE" ] && [ ! -s "$PROVIDED_CONFIG_FILE" ]; then
  CONFIG_FILE="$PROVIDED_CONFIG_FILE"
fi

# Execute the sourcehawk scan
./function/sourcehawk scan --verbosity MEDIUM --output-format "$OUTPUT_FORMAT" --config-file "$CONFIG_FILE" "$SOURCE_CODE_ROOT_DIRECTORY" 2>"$ERROR_OUTPUT_FILE"
SCAN_EXIT_CODE=$?
if [ $SCAN_EXIT_CODE -eq 0 ]; then
  exit 0
elif [ $SCAN_EXIT_CODE -eq 1 ]; then
  exit 66
elif [ $SCAN_EXIT_CODE -eq 2 ]; then
  error_and_exit 67 "Improper usage of scan"
else
  cat "$ERROR_OUTPUT_FILE" >&2
  error_and_exit 68 "Unknown error performing scan: $SCAN_EXIT_CODE"
fi
