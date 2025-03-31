#!/bin/bash
set -e

# Ensure the script is run on a Debian-based system
if ! command -v dpkg &> /dev/null; then
    echo "This script must be run on a Debian-based system."
    exit 1
fi

# Install required dependencies
echo "Installing build dependencies..."
sudo apt-get update
sudo apt-get install -y build-essential devscripts lintian dpkg-dev fakeroot \
    python3-distutils-extra python3-setuptools python3-twisted gettext \
    intltool

# Prepare the environment
echo "Preparing the build environment..."
BUILD_DIR=$(pwd)
DEB_TMP_DIR="$BUILD_DIR/debian/tmp"
mkdir -p "$DEB_TMP_DIR"

# Compile .po files into .mo files
echo "Compiling .po files..."
cd "$BUILD_DIR/po"
for po_file in *.po; do
    lang=$(basename "$po_file" .po)
    mkdir -p "$DEB_TMP_DIR/usr/share/locale/$lang/LC_MESSAGES"
    msgfmt -o "$DEB_TMP_DIR/usr/share/locale/$lang/LC_MESSAGES/epoptes.mo" "$po_file"
done
cd "$BUILD_DIR"

# Run setup.py to build and install the package
echo "Running setup.py..."
python3 setup.py build
python3 setup.py install --root="$DEB_TMP_DIR"

# Copy additional files
echo "Copying additional files..."
mkdir -p "$DEB_TMP_DIR/usr/bin"
cp bin/epoptes "$DEB_TMP_DIR/usr/bin/"

mkdir -p "$DEB_TMP_DIR/usr/lib/python3/dist-packages/twisted/plugins"
cp twisted/plugins/epoptesd.py "$DEB_TMP_DIR/usr/lib/python3/dist-packages/twisted/plugins/"

# Create the orig tarball
echo "Creating orig tarball..."
VERSION=$(dpkg-parsechangelog --show-field Version | sed 's/-.*//')
TARBALL="epoptes_${VERSION}.orig.tar.gz"
git archive --format=tar.gz --prefix=epoptes/ -o "$TARBALL" HEAD

# Build the Debian package
echo "Building the Debian package..."
debuild -us -uc -b

# Move the resulting .deb files to a separate directory
echo "Moving .deb files to output directory..."
OUTPUT_DIR="$BUILD_DIR/output"
mkdir -p "$OUTPUT_DIR"
find .. -name "epoptes*.deb" -exec mv {} "$OUTPUT_DIR/" \;

echo "Build completed. The .deb files are in the 'output' directory."