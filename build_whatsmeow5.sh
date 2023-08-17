#!/usr/bin/bash

if [ -n $TERMUX_VERSION ]; then
    apt update
    yes | pkg install -y git golang ffmpeg termux-elf-cleaner p7zip 2>/dev/null | grep -E '(Need to get |Get:|Unpacking |Setting up )'
else
    echo "The script should run on Termux"
    exit 1
fi

current_dir="$(pwd)"
tmpdir="$(mktemp -d)"

cd $tmpdir

git clone https://github.com/tulir/whatsmeow

if [ -n $TERM ]; then
    clear
fi

# Add extended support
echo -e "\n------------------------\n\nAdding extended support:-\n"
find $current_dir/res -maxdepth 1 -type f -name "*)*" -regex ".*/[0-9]+) .*" | sort -V | while read -r i; do
    echo -n " " && bash "$i"
done
echo -e "\nDone adding extended support\n\n------------------------\n"

# fix Termux permissions
if [ -n $TERMUX_VERSION ]; then
    value="true"; key="allow-external-apps"; file="/data/data/com.termux/files/home/.termux/termux.properties"; mkdir -p "$(dirname "$file")"; chmod 700 "$(dirname "$file")"; if ! grep -E '^'"$key"'=.*' $file &>/dev/null; then [[ -s "$file" && ! -z "$(tail -c 1 "$file")" ]] && newline=$'\n' || newline=""; echo "$newline$key=$value" >> "$file"; else sed -i'' -E 's/^'"$key"'=.*/'"$key=$value"'/' $file; fi
fi

cd whatsmeow/mdtest
go mod tidy

echo -e "\nFinal step, building mdtest binary. Takes about 10s~1min"

go build -ldflags="-extldflags -s" -o mdtest.bin

mdtest_script='#!/system/bin/sh

dir="$(cd "$(dirname "$0")"; pwd)"
bin_name="$(basename "$0")"
chmod 744 "$0" &>/dev/null
chmod 744 "$dir/${bin_name}.bin" &>/dev/null

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

if [ $? -eq 0 ]; then
    if [ -n $TERMUX_VERSION ]; then
        termux-elf-cleaner ${tmpdir}/whatsmeow/mdtest/mdtest.bin &>/dev/null
    fi
    cd $current_dir
    rm -rf build/mdtest.zip build/mdtest build/mdtest.bin &>/dev/null
    mkdir -p build
    cd build
    cp ${tmpdir}/whatsmeow/mdtest/mdtest.bin .
    echo "$mdtest_script" > mdtest
    chmod 744 mdtest mdtest.bin
    7z a -tzip -mx=9 -bd -bso0 mdtest.zip mdtest mdtest.bin
fi
#rm -rf $tmpdir &>/dev/null
echo $tmpdir
#go clean -cache

echo -e "\nSuccessfuly built Mdtest. Adding media support\nusing ffmpeg...\n"

cd $current_dir

bash res/build_dynamic.sh ffmpeg

if [ -n $TERMUX_VERSION ]; then
    pkg clean
fi

chmod 744 build/ffmpeg build/ffmpeg.bin

mkdir -p whatsmeow5/mdtest/ffmpeg &>/dev/null

mv build/mdtest whatsmeow5/mdtest &>/dev/null

mv build/mdtest.bin whatsmeow5/mdtest &>/dev/null

mv build/ffmpeg whatsmeow5/mdtest/ffmpeg &>/dev/null

mv build/ffmpeg.bin whatsmeow5/mdtest/ffmpeg &>/dev/null

mv build/lib-ffmpeg whatsmeow5/mdtest/ffmpeg &>/dev/null

cp -rf whatsmeow5/mdtest/ffmpeg build

cd build

echo -e "Adding ffmpeg to mdtest.zip...\n"

7z a -tzip -mx=9 -bd -bso0 mdtest.zip ffmpeg

rm -rf ffmpeg &>/dev/null

echo -e "All done! You can type this -\n  \n\" cd whatsmeow5/mdtest; ./mdtest \"\n\nType without quotes to run Mdtest\n"
