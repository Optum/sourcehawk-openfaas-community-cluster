#!/bin/bash

set -e

# Retrieve Latest Version
VERSION=$(curl -sI https://github.com/optum/sourcehawk/releases/latest | grep -i location | awk -F"/" '{ printf "%s", $NF }' | tr -d '\r\n')

# Download the binary and make it executable
DOWNLOAD_URL="https://github.com/optum/sourcehawk/releases/download/$VERSION/sourcehawk-linux-x86_64"

echo "Downloading Sourcehawk binary..."
if curl -sLk "$DOWNLOAD_URL" -o "function/sourcehawk"; then
  echo "Successfully updated Sourcehawk binary to version: $VERSION"
else
  echo "Failed to update Sourcehawk binary"
  exit 1
fi
