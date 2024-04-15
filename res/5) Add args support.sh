#!/data/data/com.termux/files/usr/bin/bash

step_name="$(basename "$0" | sed -E 's/^[0-9]+\) //' | sed -E 's/\.sh$//')"
step_number="$(basename "$0" | grep -Eo '^[0-9]+')"
echo "$step_number) $step_name"

code_body='
	//start
	if device_id != "<nil>" {
		tmp_jid, _ := parseJID(device_id)
		device_jid = fmt.Sprintf("%s", tmp_jid)
		jids := []types.JID{}
		jids = append(jids, tmp_jid)
		userinfo, error := cli.GetUserInfo(jids)
		if error != nil {
			log.Errorf("Failed to get user info: %v", error)
			} else {
				for jid, _ := range userinfo {
						default_jid = fmt.Sprintf("%s", jid)
				break
			}
		}
	}
	
	if len(args) > 0 {
		if args[0] != "pair-phone" {
			go func() {
				for {
					if cli.IsConnected() {
						break
					}
					time.Sleep(1 * time.Second)
				}
				time.Sleep(2 * time.Second)
				if !cli.IsLoggedIn() {
					fmt.Fprintln(os.Stderr, " If not paired, try running -\n\n ./mdtest pair-phone <number>\n\n (<number> is \"Country Code\" + \"Phone Number\")\n\n (ie:- \"Country Code\" = 91, then 919876543210)")
					os.Exit(1)
				}
			}()
		}
		handleCmd(strings.ToLower(args[0]), args[1:])
		if args[0] != "pair-phone" {
			return
		}
	} else {
		go func() {
			for {
				if cli.IsConnected() {
					break
				}
				time.Sleep(1 * time.Second)
			}
			time.Sleep(2 * time.Second)
			if !cli.IsLoggedIn() {
				fmt.Fprintln(os.Stderr, " If not paired, try running -\n\n ./mdtest pair-phone <number>\n\n (<number> is \"Country Code\" + \"Phone Number\")\n\n (ie:- \"Country Code\" = 91, then 919876543210)")
				os.Exit(1)
			}
		}()
	}
	//stop
'

sed -i -e "$(($(grep -nm 1 -F 'c := make(chan os.Signal, 1)' whatsmeow/mdtest/main.go | sed 's/:.*//')-1))r /dev/stdin" whatsmeow/mdtest/main.go <<< $code_body
