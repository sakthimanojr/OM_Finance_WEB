#!/bin/bash
# Clone Flutter stable SDK if not already cached
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK (stable)..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Verify Flutter installation
flutter --version

# Enable Web and install packages
flutter config --enable-web
flutter pub get

# Build production web bundle
flutter build web --release --base-href "/"
