#!/bin/bash
set -e

# Increase Dart VM heap size to prevent OOM during dart2js compilation
export DART_VM_OPTIONS="--old_gen_heap_size=2048"

# Clone Flutter stable SDK if not already cached
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK (stable)..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Enable web support & configure platform
echo "Configuring Flutter for Web..."
flutter config --enable-web --no-analytics
flutter create . --platforms web

# Install dependencies
echo "Getting dependencies..."
flutter pub get

# Build production web bundle with memory optimizations and without wasm dry run
echo "Building Web Release..."
flutter build web --release --no-wasm-dry-run --no-tree-shake-icons --base-href "/"
