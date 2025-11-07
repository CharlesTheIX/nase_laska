#!/bin/bash

declare -a platforms=("macos-arm64" "windows-x64")
declare -a targets=("aarch64-macos-gnu" "x86_64-windows-gnu")

rm -rf dist
mkdir -p dist
for i in "${!targets[@]}"; do
    target="${targets[$i]}"
    platform="${platforms[$i]}"
    echo "Building for $platform ($target)..."

    if [[ "$target" == *"macos"* ]]; then
        if zig build; then
            echo "Built $platform successfully"
        else
            echo "Failed to build $platform, skipping"
            continue
        fi
    else
        if zig build -Dtarget="$target"; then
            echo "Built $platform successfully"
        else
            echo "Failed to build $platform, skipping"
            continue
        fi
    fi

    mkdir -p "dist/$platform"

    if [[ "$target" == *"windows"* ]]; then
        cp zig-out/bin/nase_laska.exe "dist/$platform/"
    else
        cp zig-out/bin/nase_laska "dist/$platform/"
    fi

    if [ -d zig-out/bin/templates ]; then
        cp -r zig-out/bin/templates "dist/$platform/"
    fi

    if [ -d zig-out/bin/images ]; then
        cp -r zig-out/bin/images "dist/$platform/"
    fi

    if [ -d zig-out/bin/audio ]; then
        cp -r zig-out/bin/audio "dist/$platform/"
    fi
done
echo "All builds completed. Distributables are in the 'dist' directory."