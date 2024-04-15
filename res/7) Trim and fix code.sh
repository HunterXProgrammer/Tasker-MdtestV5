#!/data/data/com.termux/files/usr/bin/bash

step_name="$(basename "$0" | sed -E 's/^[0-9]+\) //' | sed -E 's/\.sh$//')"
step_number="$(basename "$0" | grep -Eo '^[0-9]+')"
echo "$step_number) $step_name"

code_body='
	//start
	"sync/atomic"
	//stop
'

sed -i -e "$(grep -nm 1 -F '"errors"' whatsmeow/message.go | sed 's/:.*//')r /dev/stdin" whatsmeow/message.go <<< $code_body

code_body='
//start
var greatestChunkOrder uint32 = 0
var currentCount uint32 = 0
var initialSync bool
//stop
'

sed -i -e "$(grep -nm 1 -F 'var pbSerializer = store.SignalProtobufSerializer' whatsmeow/message.go | sed 's/:.*//')r /dev/stdin" whatsmeow/message.go <<< $code_body

code_body='
			//start
			go func() {
				if historySync.GetSyncType() == waProto.HistorySync_RECENT {
					if atomic.LoadUint32(&greatestChunkOrder) < historySync.GetChunkOrder() {
						atomic.StoreUint32(&greatestChunkOrder, historySync.GetChunkOrder())
					}
					cli.storeHistoricalMessageSecrets(historySync.GetConversations())
					atomic.AddUint32(&currentCount, 1)
					time.Sleep(5 * time.Second)
					if  !initialSync {
						if atomic.LoadUint32(&greatestChunkOrder) == atomic.LoadUint32(&currentCount) {
							initialSync = true
							cli.Log.Infof("Initial Sync Completed")
						}
					}
				} else {
					cli.storeHistoricalMessageSecrets(historySync.GetConversations())
				}
			}()
			//stop
'

sed -i -e "$(grep -nm 1 -F 'go cli.storeHistoricalMessageSecrets(historySync.GetConversations()' whatsmeow/message.go | sed 's/:.*//')r /dev/stdin" whatsmeow/message.go <<< $code_body

sed -i '/go cli.storeHistoricalMessageSecrets(historySync.GetConversations()/d' whatsmeow/message.go

sed -i '/case "sendimg":/,/var startupTime = time.Now().Unix()/d' whatsmeow/mdtest/main.go

start_line=""
end_line=""
start_line="$(grep -nm 1 -F 'case "listgroups":' whatsmeow/mdtest/main.go | grep -Eo '^[0-9]+')"
end_line="$(wc -l whatsmeow/mdtest/main.go | grep -Eo "^[0-9]+")"
i="$start_line"

while (( $i < $end_line ))
do
    ((i++))
    if sed -n "${i}p" whatsmeow/mdtest/main.go | grep -Eq 'case ".*":'
    then
        ((i--))
        sed -i "${start_line},${i}d" whatsmeow/mdtest/main.go
        break
    fi
done

code_body='
		//start
		time.Sleep(2 * time.Second)
		//stop
'

sed -i -e "$(grep -nm 1 -F 'time.Sleep(autoReconnectDelay)' whatsmeow/client.go | sed 's/:.*//')r /dev/stdin" whatsmeow/client.go <<< $code_body

sed -i '/time.Sleep(autoReconnectDelay)/d' whatsmeow/client.go

code_body='
		//start
		mutations, newState, err := cli.appStateProc.DecodePatches(patches, state, false)
		//stop
'

sed -i -e "$(grep -nm 1 -F 'mutations, newState, err := cli.appStateProc.DecodePatches(patches, state, true)' whatsmeow/appstate.go | sed 's/:.*//')r /dev/stdin" whatsmeow/appstate.go <<< $code_body

sed -i '/mutations, newState, err := cli.appStateProc.DecodePatches(patches, state, true)/d' whatsmeow/appstate.go

code_body='
		//start
		is_connected = false
		waitSync = sync.WaitGroup{}
		//stop
'

sed -i -e "$(grep -nm 1 -F 'case "reconnect":' whatsmeow/mdtest/main.go | sed 's/:.*//')r /dev/stdin" whatsmeow/mdtest/main.go <<< $code_body

start_line=""
end_line=""
start_line="$(grep -nm 1 -F 'case "sendpoll":' whatsmeow/mdtest/main.go | grep -Eo '^[0-9]+')"
end_line="$(wc -l whatsmeow/mdtest/main.go | grep -Eo "^[0-9]+")"
i="$start_line"

while (( $i < $end_line ))
do
    ((i++))
    if sed -n "${i}p" whatsmeow/mdtest/main.go | grep -Eq 'case ".*":'
    then
        ((i--))
        sed -i "${start_line},${i}d" whatsmeow/mdtest/main.go
        break
    fi
done

start_line=""
end_line=""
start_line="$(grep -nm 1 -F 'case *events.HistorySync:' whatsmeow/mdtest/main.go | grep -Eo '^[0-9]+')"
end_line="$(wc -l whatsmeow/mdtest/main.go | grep -Eo "^[0-9]+")"
i="$start_line"

while (( $i < $end_line ))
do
    ((i++))
    if sed -n "${i}p" whatsmeow/mdtest/main.go | grep -Eq 'case \*events\..*:'
    then
        ((i--))
        sed -i "${start_line},${i}d" whatsmeow/mdtest/main.go
        break
    fi
done
