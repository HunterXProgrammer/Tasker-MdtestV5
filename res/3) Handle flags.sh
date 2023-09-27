#!/data/data/com.termux/files/usr/bin/bash

step_name="$(basename "$0" | sed -E 's/^[0-9]+\) //' | sed -E 's/\.sh$//')"
step_number="$(basename "$0" | grep -Eo '^[0-9]+')"
echo "$step_number) $step_name"

code_body='
	//start
	currentDir, _ = os.Getwd()
	os.RemoveAll(filepath.Join(currentDir, ".tmp"))
	ffmpegScript := "ffmpeg"
	ffmpegScriptPath = filepath.Join(filepath.Dir(currentDir), "mdtest", "ffmpeg", ffmpegScript)
	os.Chmod(filepath.Dir(ffmpegScriptPath), os.FileMode(0744))
	os.Chmod(ffmpegScriptPath, os.FileMode(0744))
	is_default := true
	if *httpPort < 1024 || *httpPort > 65535 || *httpPort == 9990 {
		if *httpPort != 0 {
			is_default = false
		}
		*httpPort = 7774
	} else {
		is_default = false
	}
	
	if *isMode == "" {
		*isMode = "none"
	}
	
	if !is_default {
		host := "localhost"
		check_timeout := time.Second * 1
		conn_port, _ := net.DialTimeout("tcp", net.JoinHostPort(host, fmt.Sprintf("%d", *httpPort)), check_timeout)
		if conn_port != nil {
			log.Infof("Port %d is already being used, exiting...", *httpPort)
			conn_port.Close()
			os.Exit(1)
		}
	}
	//stop
'

sed -i -e "$(grep -nm 1 -F 'log = waLog.Stdout("Main", logLevel, true)' whatsmeow/mdtest/main.go | sed 's/:.*//')r /dev/stdin" whatsmeow/mdtest/main.go <<< $code_body