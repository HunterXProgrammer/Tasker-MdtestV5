#!/usr/bin/bash

if [ -n "$TERMUX_VERSION" ]; then
    apt update
    yes | pkg upgrade git golang ffmpeg termux-elf-cleaner p7zip 2>/dev/null | grep -E '(Need to get |Get:|Unpacking |Setting up )'
else
    echo "This script should run on Termux"
    exit 1
fi

CURRENT_DIR="$(pwd)"
TMP_DIR="$(mktemp -d)"

cd "$TMP_DIR"

git clone --depth 1 https://github.com/tulir/whatsmeow

clear 2>/dev/null

# Add extended support
echo -e "\n------------------------\n\nAdding extended support:-\n"
find "$CURRENT_DIR/res" -maxdepth 1 -type f -name "*)*" -regex ".*/[0-9]+) .*" | sort -V | while read -r i; do
    echo -n " " && bash "$i"
done
echo -e "\nDone adding extended support\n\n------------------------\n"

# fix Termux permissions
value="true"; key="allow-external-apps"; file="/data/data/com.termux/files/home/.termux/termux.properties"; mkdir -p "$(dirname "$file")"; chmod 700 "$(dirname "$file")"; if ! grep -E '^'"$key"'=.*' $file &>/dev/null; then [[ -s "$file" && ! -z "$(tail -c 1 "$file")" ]] && newline=$'\n' || newline=""; echo "$newline$key=$value" >> "$file"; else sed -i'' -E 's/^'"$key"'=.*/'"$key=$value"'/' $file; fi

cd whatsmeow/mdtest
go mod tidy

echo -e "\nFinal step, building mdtest binary. Takes about 10s~1min"

mdtest_script='#!/system/bin/sh

dir="$(cd "$(dirname "$0")"; pwd)"
bin_name="$(basename "$0")"
chmod 755 "$0" "$dir/${bin_name}.bin" 2>/dev/null >/dev/null

if [ $(getprop ro.build.version.sdk) -gt 28 ]; then
    if getprop ro.product.cpu.abilist | grep -q "64"
    then
        exec /system/bin/linker64 "$dir/${bin_name}.bin" "$@"
    else
        exec /system/bin/linker "$dir/${bin_name}.bin" "$@"
    fi
else
   exec "$dir/${bin_name}.bin" "$@"
fi'

go build -ldflags="-extldflags -s" -o mdtest.bin

if [ $? -eq 0 ]; then
    termux-elf-cleaner "$TMP_DIR/whatsmeow/mdtest/mdtest.bin" &>/dev/null
    cd "$CURRENT_DIR"
    rm -rf build/mdtest.zip build/mdtest build/mdtest.bin &>/dev/null
    mkdir -p build
    cd build
    cp "$TMP_DIR/whatsmeow/mdtest/mdtest.bin" .
    if [ $? -ne 0 ]; then
        rm -rf "$TMP_DIR" &>/dev/null
        echo "Error occured, exiting..."
        exit 1
    fi
    echo "$mdtest_script" > mdtest
    chmod 755 mdtest mdtest.bin
    7z a -tzip -mx=9 -bd -bso0 mdtest.zip mdtest mdtest.bin
    rm -rf mdtest mdtest.bin &>/dev/null
else
    rm -rf "$TMP_DIR" &>/dev/null
    echo "Error occured, exiting..."
    exit 1
fi

rm -rf "$TMP_DIR" &>/dev/null
#echo $TMP_DIR
#exit 0
#go clean -cache

echo -e "\nSuccessfuly built Mdtest. Adding media support\nusing ffmpeg...\n"

cd "$CURRENT_DIR"

bash res/build_dynamic.sh ffmpeg

pkg clean

chmod 755 build/ffmpeg build/ffmpeg.bin

rm -rf ffmpeg &>/dev/null

mkdir -p ffmpeg &>/dev/null

mv build/ffmpeg ffmpeg &>/dev/null

mv build/ffmpeg.bin ffmpeg &>/dev/null

mv build/lib-ffmpeg ffmpeg &>/dev/null

mv ffmpeg build &>/dev/null 

cd build

echo -e "Adding ffmpeg to mdtest.zip...\n"

7z a -tzip -mx=9 -bd -bso0 mdtest.zip ffmpeg

rm -rf ffmpeg &>/dev/null

mkdir -p ~/whatsmeow5/mdtest

7z x -aoa mdtest.zip -o$HOME/whatsmeow5/mdtest &>/dev/null

chmod 755 ~/whatsmeow5/mdtest/mdtest

echo -e "All done! You can type this -\n  \n\" cd ~/whatsmeow5/mdtest; ./mdtest \"\n\nType without quotes to run Mdtest\n"
