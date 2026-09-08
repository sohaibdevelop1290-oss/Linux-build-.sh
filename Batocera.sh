#!/bin/bash
set -e

echo "=========================================="
echo " 1. Downloading Batocera Linux Source    "
echo "=========================================="
if [ ! -d "batocera.linux" ]; then
    git clone https://github.com/batocera-linux/batocera.linux.git
fi

cd batocera.linux

echo "=========================================="
echo " 2. Updating Buildroot Submodules         "
echo "=========================================="
git submodule init
git submodule update

echo "=========================================="
echo " 3. Injecting Device Tree & Kernel Source "
echo "=========================================="
# Setup OnePlus Nord N100 Device Tree
mkdir -p board/oneplus/billie2
if [ ! -d "board/oneplus/billie2/.git" ]; then
    git clone https://gitlab.com/sohaibdevelop1290/oneplus-billie2.git board/oneplus/billie2/
fi

# Setup UBports SM4250 Kernel
if [ ! -d "linux-custom/.git" ]; then
    git clone https://gitlab.com/sohaibdevelop1290/kernel-oneplus-sm4250.git linux-custom/
fi

echo "=========================================="
echo " 4. Building Batocera Docker Environment  "
echo "=========================================="
make build-docker-image

echo "=========================================="
echo " 5. Compiling Batocera Image (sm6115)     "
echo "=========================================="
make sm6115-build

echo "=========================================="
echo " Compilation Finished Successfully!       "
echo " Target Image: output/sm6115/images/      "
echo "=========================================="
