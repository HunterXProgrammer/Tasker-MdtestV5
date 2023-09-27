#!/data/data/com.termux/files/usr/bin/bash

step_name="$(basename "$0" | sed -E 's/^[0-9]+\) //' | sed -E 's/\.sh$//')"
step_number="$(basename "$0" | grep -Eo '^[0-9]+')"
echo "$step_number) $step_name"

code_body='
	//start
	device_id = fmt.Sprintf("%s", device.ID)
	//stop
'

sed -i -e "$(($(grep -nm 1 -F 'cli = whatsmeow.NewClient(device, waLog.Stdout("Client", logLevel, true))' whatsmeow/mdtest/main.go | sed 's/:.*//')-1))r /dev/stdin" whatsmeow/mdtest/main.go <<< $code_body

code_body='
	//start
	version, _ := store.ParseVersion(fmt.Sprintf("%s", store.GetWAVersion()))
	//store.SetOSInfo("Mdtest (V5)(" + fmt.Sprintf("%d", *httpPort) + ")", version)
 	store.SetOSInfo("Firefox (Android)", version)
	args := flag.Args()
	//stop
'

sed -i '/ch, err := cli.GetQRChannel(context.Background())/,/cli.AddEventHandler(handler)/ {
/cli.AddEventHandler(handler)/!d
}' whatsmeow/mdtest/main.go

sed -i -e "$(($(grep -nm 1 -F 'cli.AddEventHandler(handler)' whatsmeow/mdtest/main.go | sed 's/:.*//')-1))r /dev/stdin" whatsmeow/mdtest/main.go <<< $code_body
