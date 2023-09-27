#!/data/data/com.termux/files/usr/bin/bash

step_name="$(basename "$0" | sed -E 's/^[0-9]+\) //' | sed -E 's/\.sh$//')"
step_number="$(basename "$0" | grep -Eo '^[0-9]+')"
echo "$step_number) $step_name"

code_body='
		//start
		if *isMode == "both" {
			if is_connected {
				waitSync.Add(1)
			}
			go parseReceivedMessage(evt, &waitSync)
		}
		//stop
'

sed -i -e "$(grep -nm 1 -F 'log.Infof("Received message %s from %s (%s): %+v", evt.Info.ID, evt.Info.SourceString(), strings.Join(metaParts, ", "), evt.Message)' whatsmeow/mdtest/main.go | sed 's/:.*//')r /dev/stdin" whatsmeow/mdtest/main.go <<< $code_body
