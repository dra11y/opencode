#!/usr/bin/env bash
set -euo pipefail

# Update script for dra11y's opencode fork with linear retry patch
# Usage: ./update-opencode.sh

REPO_OWNER="dra11y"
INSTALL_DIR="$HOME/.opencode/bin"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔄 Updating opencode (dra11y fork with linear retry patch)${NC}"

# Detect OS and arch
raw_os=$(uname -s)
os=$(echo "$raw_os" | tr '[:upper:]' '[:lower:]')
case "$raw_os" in
  Darwin*) os="darwin" ;;
  Linux*) os="linux" ;;
  MINGW*|MSYS*|CYGWIN*) os="windows" ;;
esac

arch=$(uname -m)
if [[ "$arch" == "aarch64" ]]; then
  arch="arm64"
fi
if [[ "$arch" == "x86_64" ]]; then
  arch="x64"
fi

if [ "$os" = "darwin" ] && [ "$arch" = "x64" ]; then
  rosetta_flag=$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)
  if [ "$rosetta_flag" = "1" ]; then
    arch="arm64"
  fi
fi

# Determine target and filename
target="$os-$arch"
if [ "$os" = "linux" ]; then
  archive_ext=".tar.gz"
else
  archive_ext=".zip"
fi

filename="opencode-$target$archive_ext"

# Get latest version
echo -e "${YELLOW}📦 Fetching latest version from dra11y/opencode${NC}"
latest_version=$(curl -s https://api.github.com/repos/$REPO_OWNER/opencode/releases/latest | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p')

if [[ $? -ne 0 || -z "$latest_version" ]]; then
  echo -e "${RED}❌ Failed to fetch version information${NC}"
  exit 1
fi

# Check current version
if command -v opencode >/dev/null 2>&1; then
  current_version=$(opencode --version 2>/dev/null || echo "unknown")
  echo -e "${YELLOW}📌 Current version: $current_version${NC}"
  echo -e "${YELLOW}🆕 Latest version: $latest_version${NC}"
  
  if [[ "$current_version" == "$latest_version" ]]; then
    echo -e "${GREEN}✅ Already up to date!${NC}"
    exit 0
  fi
else
  echo -e "${YELLOW}📌 No installation found${NC}"
  echo -e "${YELLOW}🆕 Installing version: $latest_version${NC}"
fi

# Download and install
echo -e "${YELLOW}⬇️  Downloading opencode-$latest_version...${NC}"
url="https://github.com/$REPO_OWNER/opencode/releases/latest/download/$filename"

tmp_dir="${TMPDIR:-/tmp}/opencode_update_$$"
mkdir -p "$tmp_dir"

curl -fsSL "$url" -o "$tmp_dir/$filename"

if [ "$os" = "linux" ]; then
  tar -xzf "$tmp_dir/$filename" -C "$tmp_dir"
else
  unzip -q "$tmp_dir/$filename" -d "$tmp_dir"
fi

# Create backup and install
if [ -f "$INSTALL_DIR/opencode" ]; then
  echo -e "${YELLOW}💾 Creating backup...${NC}"
  cp "$INSTALL_DIR/opencode" "$INSTALL_DIR/opencode.backup.$(date +%s)"
fi

echo -e "${YELLOW}📦 Installing...${NC}"
mkdir -p "$INSTALL_DIR"
mv "$tmp_dir/opencode" "$INSTALL_DIR/opencode"
chmod 755 "$INSTALL_DIR/opencode"

# Clean up
rm -rf "$tmp_dir"

# Verify installation
new_version=$("$INSTALL_DIR/opencode" --version 2>/dev/null || echo "unknown")
echo -e "${GREEN}✅ Installation complete!${NC}"
echo -e "${GREEN}📌 New version: $new_version${NC}"

# Check if in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo -e "${YELLOW}⚠️  Warning: $INSTALL_DIR is not in your PATH${NC}"
  echo -e "${YELLOW}   Add to your shell profile: export PATH=\$PATH:$INSTALL_DIR${NC}"
  echo -e "${YELLOW}   Then restart your terminal or run: export PATH=\$PATH:$INSTALL_DIR${NC}"
fi

echo -e "${GREEN}🎉 Your opencode (dra11y fork with linear retry) is updated!${NC}"