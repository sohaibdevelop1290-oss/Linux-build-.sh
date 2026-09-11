#!/bin/bash
set -e

# Disable all interactive dpkg/apt prompts completely
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export TZ=UTC

echo "=========================================="
echo " Step 1: Docker Environment Setup         "
echo "=========================================="
# Install Docker and add current user to docker group silently
sudo apt-get update -y
sudo -E apt-get install -y \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  docker.io curl jq

sudo usermod -aG docker $USER || true
sudo systemctl start docker || sudo service docker start || true

echo "=========================================="
echo " Step 2: Download Batocera Sources        "
echo "=========================================="
if [ ! -d "batocera.linux" ]; then
    git clone https://github.com/batocera-linux/batocera.linux.git
fi

cd batocera.linux

# Init and update submodules (Buildroot)
git submodule init
git submodule update

echo "=========================================="
echo " Step 3: Injecting Device Tree & Kernel   "
echo "=========================================="
mkdir -p board/oneplus/billie2
if [ ! -d "board/oneplus/billie2/.git" ]; then
    git clone https://gitlab.com/sohaibdevelop1290/oneplus-billie2.git board/oneplus/billie2/
fi

if [ ! -d "linux-custom/.git" ]; then
    git clone https://gitlab.com/sohaibdevelop1290/kernel-oneplus-sm4250.git linux-custom/
fi

echo "=========================================="
echo " Step 4: Install Build Environment        "
echo "=========================================="
# Official command from Wiki Step 3
make build-docker-image

echo "=========================================="
echo " Step 5: Build Image (sm6115)             "
echo "=========================================="
# Official syntax: make <arch>-build
make sm6115-build

echo "=========================================="
echo " Step 6: Uploading Image to GoFile        "
echo "=========================================="
OUTPUT_DIR="output/sm6115/images"

if [ -d "$OUTPUT_DIR" ]; then
    SERVER=$(curl -s https://api.gofile.io/servers | jq -r '.data.servers[0].name')
    for FILE in $OUTPUT_DIR/*; do
        if [ -f "$FILE" ]; then
            echo "Uploading $FILE..."
            RESPONSE=$(curl -s -F "file=@$FILE" "https://${SERVER}.gofile.io/contents/uploadfile")
            DOWNLOAD_LINK=$(echo $RESPONSE | jq -r '.data.downloadPage')
            echo "----------------------------------------"
            echo " File Uploaded Successfully!"
            echo " Download Link: $DOWNLOAD_LINK"
            echo "----------------------------------------"
        fi
    done
else
    echo "Error: Output folder $OUTPUT_DIR not found!"
    exit 1
fi

echo "=========================================="
echo " Process Finished Successfully!           "
echo "=========================================="

