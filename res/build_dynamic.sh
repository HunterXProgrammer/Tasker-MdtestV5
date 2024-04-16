#!/usr/bin/bash

if [ -n "$TERMUX_VERSION" ]; then
    apt update
else
    echo "This script should run on Termux"
    exit 1
fi

yes | pkg install -y p7zip ldd binutils command-not-found tur-repo root-repo x11-repo

mkdir -p "build" &>/dev/null
cd build

package_script='#!/system/bin/sh

dir="$(cd "$(dirname "$0")"; pwd)"
bin_name="$(basename "$0")"
chmod 755 "$0" "$dir/${bin_name}.bin" &>/dev/null
chmod -R 755 "$dir/lib-${bin_name}" &>/dev/null
export LD_LIBRARY_PATH="$dir/lib-${bin_name}"

if [ $(getprop ro.build.version.sdk) -gt 28 ]; then
    if getprop ro.product.cpu.abilist | grep -q "64"; then
        exec /system/bin/linker64 "$dir/${bin_name}.bin" "$@"
    else
        exec /system/bin/linker "$dir/${bin_name}.bin" "$@"
    fi
else
    exec "$dir/${bin_name}.bin" "$@"
fi'

if [ -n "$*" ]; then
    package_list=("$@")
else
    package_list=("ffmpeg")
fi

echo ""

for package in "${package_list[@]}"; do
    is_valid="true"
    echo "  Selected package ${package}..."
    if ! command -v "$package" &>/dev/null; then
        pkg_install="$("$PREFIX/libexec/termux/command-not-found" "$package" 2>&1 | grep "pkg install" | head -n 1 | sed "s/.* //g")"
        if [ -n "$pkg_install" ]; then
            echo ""
            yes | pkg install -y "$pkg_install"
            is_valid="true"
        else
            echo -e "\n  Package ${package} not valid. Skipping..."
            is_valid="false"
        fi
    fi
    if [ "$is_valid" = "true" ]; then
        rm -rf "${package}.zip" "$package" "${package}.bin" "lib-$package" &>/dev/null
        echo -e "\n  Checking package..."
        if ! readelf -d "$(command -v "$package")" 2>/dev/null | grep -q "Dynamic section at"; then
            is_valid="false"
        fi
        if [ "$is_valid" = "true" ]; then
            echo "$package_script" > "$package"
            cp -L "$(command -v "$package")" "${package}.bin"
            mkdir -p "lib-$package"
            echo -e "\n  Getting dependencies..."
            for libpath in $(ldd "$(command -v "$package")" | grep -F "/data/data/com.termux/" | sed "s/.* \//\//" | sed "s/ .*//"); do
                cp -L "$libpath" "lib-$package" &>/dev/null
            done
            echo -e "\n  Zipping package..."
            chmod 755 "$package" "${package}.bin" &>/dev/null
            chmod -R 755 "lib-$package" &>/dev/null
            7z a -tzip -mx=9 -bd -bso0 "${package}.zip" "$package" "${package}.bin" "lib-$package"
        else
            echo -e "\n  Package ${package} not valid. Skipping..."
        fi
        echo -e "\n  Done\n\n-------\n"
    fi
done
