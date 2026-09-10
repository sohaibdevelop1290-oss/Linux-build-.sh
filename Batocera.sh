#!/bin/bash
set -e

echo "=========================================="
echo " 1. Installing & Starting Docker Engine   "
echo "=========================================="
sudo apt-get update -y
sudo apt-get install -y docker.io curl jq
sudo systemctl start docker || sudo service docker start

echo "=========================================="
echo " 2. Downloading Batocera Linux Source    "
echo "=========================================="
if [ ! -d "batocera.linux" ]; then
    git clone https://github.com/batocera-linux/batocera.linux.git
fi

cd batocera.linux

echo "=========================================="
echo " 3. Updating Buildroot Submodules         "
echo "=========================================="
git submodule init
git submodule update

echo "=========================================="
echo " 4. Injecting Device Tree & Kernel Source "
echo "=========================================="
mkdir -p board/oneplus/billie2
if [ ! -d "board/oneplus/billie2/.git" ]; then
    git clone https://gitlab.com/sohaibdevelop1290/oneplus-billie2.git board/oneplus/billie2/
fi

if [ ! -d "linux-custom/.git" ]; then
    git clone https://gitlab.com/sohaibdevelop1290/kernel-oneplus-sm4250.git linux-custom/
fi

echo "=========================================="
echo " 5. Building Batocera Docker Environment  "
echo "=========================================="
make build-docker-image

echo "=========================================="
echo " 6. Compiling Batocera Image (sm6115)     "
echo "=========================================="
make sm6115-build

echo "=========================================="
echo " 7. Uploading Output Artifacts to GoFile  "
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
            echo " Download Link: $DOWNLOAD_LINK"
            echo "----------------------------------------"
        fi
    done
fi
