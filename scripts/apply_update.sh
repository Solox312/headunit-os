#!/bin/bash
# ==============================================================================
# HeadUnit OS — Extract & Restart Service Tool
# Extracts pre-compiled update bundle and restarts headunit.service.
# ==============================================================================

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

if [ "$#" -lt 2 ]; then
  echo -e "${RED}Usage: $0 <update_tar_gz_path> <target_dir>${NC}"
  exit 1
fi

UPDATE_FILE="$1"
TARGET_DIR="$2"

echo -e "${CYAN}Starting extraction...${NC}"
if [ ! -f "$UPDATE_FILE" ]; then
  echo -e "${RED}Error: Update package not found at $UPDATE_FILE${NC}"
  exit 1
fi

# Ensure target directory exists
mkdir -p "$TARGET_DIR"

echo -e "${CYAN}Extracting update package to $TARGET_DIR...${NC}"
tar -xzf "$UPDATE_FILE" -C "$TARGET_DIR"
echo -e "${GREEN}✓ Extraction complete.${NC}"

echo -e "${CYAN}Restarting HeadUnit OS Service...${NC}"
sudo systemctl restart headunit.service
echo -e "${GREEN}✓ Service restart signal sent.${NC}"
echo -e "${GREEN}Update applied successfully!${NC}"
