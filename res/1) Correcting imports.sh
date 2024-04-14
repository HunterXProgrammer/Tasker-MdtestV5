#!/data/data/com.termux/files/usr/bin/bash

step_name="$(basename "$0" | sed -E 's/^[0-9]+\) //' | sed -E 's/\.sh$//')"
step_number="$(basename "$0" | grep -Eo '^[0-9]+')"
echo "$step_number) $step_name"

code_body='
	//start
	"io"
	"io/ioutil"
	"crypto/sha256"
	"net"
	"bytes"
	"path/filepath"
	"github.com/zRedShift/mimemagic"
	"github.com/otiai10/opengraph/v2"
	"image"
	"image/jpeg"
	_ "image/png"
	"os/exec"
	"sync"
	"go.mau.fi/util/random"
	//stop
'

sed -i -e "$(grep -nm 1 -F '"errors"' whatsmeow/mdtest/main.go | sed 's/:.*//')r /dev/stdin" whatsmeow/mdtest/main.go <<< $code_body

sed -i '/"errors"/d' whatsmeow/mdtest/main.go

sed -i '/"mime"/d' whatsmeow/mdtest/main.go

sed -i '/"github.com\/mdp\/qrterminal\/v3"/d' whatsmeow/mdtest/main.go
