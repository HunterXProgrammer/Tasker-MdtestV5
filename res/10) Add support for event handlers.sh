#!/data/data/com.termux/files/usr/bin/bash

step_name="$(basename "$0" | sed -E 's/^[0-9]+\) //' | sed -E 's/\.sh$//')"
step_number="$(basename "$0" | grep -Eo '^[0-9]+')"
echo "$step_number) $step_name"

code_body='
	//start
	case *events.OfflineSyncCompleted:
		go func() {
			waitSync.Wait()
			log.Infof("Offline Sync Completed")
			waitSync = sync.WaitGroup{}
		}()
	case *events.Disconnected:
		is_connected = false
		waitSync = sync.WaitGroup{}
		log.Infof("Bad network, mdtest is waiting for reconnection")
		err := cli.Connect()
		if err != nil {
			log.Errorf("Failed to connect: %v", err)
		}
	//stop
'

sed -i -e "$(($(grep -nm 1 -F 'case *events.AppState:' whatsmeow/mdtest/main.go | sed 's/:.*//')-1))r /dev/stdin" whatsmeow/mdtest/main.go <<< $code_body

code_body='
		//start
		is_connected = false
		waitSync = sync.WaitGroup{}
		if !keepalive_timeout {
			keepalive_timeout = true
			for {
				cli.Disconnect()
				err := cli.Connect()
				if err == nil {
					break
				}
				log.Errorf("Failed to connect after keepalive timeout: %v", err)
				time.Sleep(2 * time.Second)
			}
			keepalive_timeout = false
		}
		//stop
'

sed -i -e "$(grep -nm 1 -F 'log.Debugf("Keepalive timeout event: %+v", evt)' whatsmeow/mdtest/main.go | sed 's/:.*//')r /dev/stdin" whatsmeow/mdtest/main.go <<< $code_body

code_body='
				//start
				is_connected = true
				if *isMode == "both" {
					updatedGroupInfo = false
					groups, err := cli.GetJoinedGroups()
					if err == nil {
						jsonContent, err := json.MarshalIndent(groups, "", "  ")
						if err == nil {
							result := make(map[string]interface{})
							result["groups"] = json.RawMessage(jsonContent)
							groupData, err := json.MarshalIndent(result, "", "  ")
							if err == nil {
								json.Unmarshal(groupData, &groupInfo)
							}
						}
					}
					updatedGroupInfo = true
					log.Infof("Receive/Send Mode Enabled")
					log.Infof("Will Now Receive/Send Messages In Tasker")
					go MdtestStart()
				} else if *isMode == "send" {
					log.Infof("Send Mode Enabled")
					log.Infof("Can Now Send Messages From Tasker")
					go MdtestStart()
				}
				//stop
'

grep -n -F 'log.Infof("Marked self as available")' whatsmeow/mdtest/main.go | sed 's/:.*//' | sort -Vr | while read -r line; do sed -i -e "${line}r /dev/stdin" whatsmeow/mdtest/main.go <<< "$code_body"; done
