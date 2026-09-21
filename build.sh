#!/bin/bash
set -e

# Clone Flutter stable SDK if not already cached
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK (stable)..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Enable web support & configure platform
echo "Configuring Flutter for Web..."
flutter config --enable-web
flutter create . --platforms web

# Install dependencies
echo "Getting dependencies..."
flutter pub get

# Build production web bundle
echo "Building Web Release..."
flutter build web --release --base-href "/"
