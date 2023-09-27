#!/data/data/com.termux/files/usr/bin/bash

step_name="$(basename "$0" | sed -E 's/^[0-9]+\) //' | sed -E 's/\.sh$//')"
step_number="$(basename "$0" | grep -Eo '^[0-9]+')"
echo "$step_number) $step_name"

code_body='
			//start
			os.Exit(1)
			//stop
'

sed -i '/log.Errorf("Usage: pair-phone <number>")/,/return/ {
/log.Errorf("Usage: pair-phone <number>")/!d
}' whatsmeow/mdtest/main.go

sed -i -e "$(grep -nm 1 -F 'log.Errorf("Usage: pair-phone <number>")' whatsmeow/mdtest/main.go | sed 's/:.*//')r /dev/stdin" whatsmeow/mdtest/main.go <<< $code_body

start_line="$(($(grep -nm 1 -F 'linkingCode, err := cli.PairPhone(args[0], true, whatsmeow.PairClientChrome, "Chrome (Linux)")' whatsmeow/mdtest/main.go | sed 's/:.*//')-1))"

sed -i '/linkingCode, err := cli.PairPhone(args\[0\], true, whatsmeow.PairClientChrome, "Chrome (Linux)")/,/fmt.Println("Linking code:", linkingCode)/d' whatsmeow/mdtest/main.go

code_body='
		//start
		counter := 0
		for counter < 10 {
			if cli.IsConnected() {
				break
			}
			counter++
			time.Sleep(1 * time.Second)
		}
		if counter < 10 {
			time.Sleep(1 * time.Second)
			if !cli.IsConnected() {
				log.Errorf("Probably logged out, try again")
				os.Exit(1)
			}
			if cli.IsLoggedIn() {
				log.Infof("Already paired")
				os.Exit(1)
			}
		} else {
			log.Errorf("Bad network, try again")
			os.Exit(1)
		}
		linkingCode, err := cli.PairPhone(args[0], true, whatsmeow.PairClientUnknown, "Firefox (Android)")
		if err != nil {
			panic(err)
		}
		log.Infof(`Linking code : "%s"`, linkingCode)
		//stop
'

sed -i -e "${start_line}r /dev/stdin" whatsmeow/mdtest/main.go <<< $code_body
