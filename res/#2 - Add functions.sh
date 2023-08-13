#!/data/data/com.termux/files/usr/bin/bash

step_name="$(basename "$0" | sed -E 's/^#[0-9]+ - //' | sed -E 's/\.sh$//')"
step_number="$(basename "$0" | grep -Eo '^#[0-9]+' | sed -E 's/#//')"
echo "$step_number) $step_name"

code_body='
//start
var server *http.Server
var is_connected bool
var device_id string
var device_jid string
var default_jid string

func sendHttpPost(json_data string, path string) {
	send_http := &http.Client{
		Timeout: 1 * time.Second,
	}
	
	jsonBody := []byte(json_data)
	bodyReader := bytes.NewReader(jsonBody)
	
	requestURL := fmt.Sprintf("http://localhost:9990" + path)
	req, err := http.NewRequest(http.MethodPost, requestURL, bodyReader)
	if err == nil {
		resp, error := send_http.Do(req)
		if error == nil {
			resp.Body.Close()
		}
	}
	return
}

func mdtest(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.Error(w, "404 not found.", http.StatusNotFound)
		log.Errorf("Invalid request path, 404 not found.")
		return
	}

	switch r.Method {
	case "GET":
		if is_connected {
			if *isMode == "both" {
		    	log.Infof("get request received, mdtest is running in both mode")
		    	io.WriteString(w, "mdtest is running in both mode")
	    	} else if *isMode == "receive" {
	    		log.Infof("get request received, mdtest is running in receive mode")
		    	io.WriteString(w, "mdtest is running in receive mode")
    		} else if *isMode == "send" {
    			log.Infof("get request received, mdtest is running in send mode")
		    	io.WriteString(w, "mdtest is running in send mode")
			}
	    } else {
	    	log.Infof("get request received, mdtest is waiting for reconnection")
		    io.WriteString(w, "Bad network, mdtest is waiting for reconnection")
    	}
    	return
	case "POST":
  	  dec := json.NewDecoder(r.Body)
	    for {
	    	argsData := struct {
				Args []string `json:"args"`
			}{}
			
			if err := dec.Decode(&argsData); err == io.EOF {
				break
			} else if err != nil {
				log.Errorf("Error: %s", err)
				return
			}
			
			args := []string{}
			
			for _, argsValue := range argsData.Args {
				args = append(args, argsValue)
			}
			
			if len(args) < 1 {
				io.WriteString(w, "command received")
				return
			}
			
			if args[0] == "stop" {
				io.WriteString(w, "exiting")
				go func() {
					time.Sleep(1 * time.Second)
					kill_server()
					log.Infof("Exit command Received, exiting...")
					cli.Disconnect()
					os.Exit(0)
				}()
				return
			} else if args[0] == "restart" {
				io.WriteString(w, "restarting")
				go func() {
					time.Sleep(1 * time.Second)
					kill_server()
					if *isMode == "both" {
						log.Infof("Receive/Send Mode Enabled")
		            	log.Infof("Will Now Receive/Send Messages In Tasker")
	            		go MdtestStart()
            		} else if *isMode == "receive" {
            			log.Infof("Receive Mode Enabled")
		            	log.Infof("Will Now Receive Messages In Tasker")
	            		go MdtestStart()
	            	} else if *isMode == "send" {
	            		log.Infof("Send Mode Enabled")
		            	log.Infof("Can Now Send Messages From Tasker")
	            		go MdtestStart()
            		}
				}()
				return
			}
			io.WriteString(w, "command received")
			if *isMode == "both" ||  *isMode == "send" {
				go handleCmd(strings.ToLower(args[0]), args[1:])
			}
		}
	    return
	default:
		log.Errorf("%s, only GET and POST methods are supported.", w)
		return
	}
}


func kill_server() {
	if server_running {
		server.Close()
		server_running = false
		log.Infof("closed")
	}
}

func MdtestStart() {
	if !server_running {
		mux := http.NewServeMux()
		mux.HandleFunc("/", mdtest)
		server = &http.Server{
			Addr:    "localhost:" + fmt.Sprintf("%d", *httpPort),
			Handler: mux,
		}
		log.Infof("mdtest started")
		server_running = true
		server.ListenAndServe()
		server_running = false
		log.Infof("mdtest stopped")
	}
}

func AppendToJSON(initialJSON string, keyword string, data interface{}) (string, error) {
	myJSON, err := FromJSON(initialJSON)
	if err != nil {
		return "", fmt.Errorf("error parsing initial JSON: %w", err)
	}
	
	key := keyword

	switch data := data.(type) {
	case string:
		myJSON[key] = data
	case []interface{}:
		myJSON[key] = data
	default:
		return "", fmt.Errorf("unsupported data type: %T", data)
	}

	jsonString, err := ToJSON(myJSON)
	if err != nil {
		return "", fmt.Errorf("error converting to JSON: %w", err)
	}

	return jsonString, nil
}

func FromJSON(jsonString string) (map[string]interface{}, error) {
	var jsonData map[string]interface{}
	err := json.Unmarshal([]byte(jsonString), &jsonData)
	if err != nil {
		return nil, err
	}
	return jsonData, nil
}

func ToJSON(jsonData map[string]interface{}) (string, error) {
	jsonBytes, err := json.Marshal(jsonData)
	if err != nil {
		return "", err
	}
	return string(jsonBytes), nil
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func resizeImage(img image.Image) image.Image {
	width := img.Bounds().Dx()
	height := img.Bounds().Dy()
	newWidth := width
	newHeight := height
	maxSize := 299
	
	if !(width <= maxSize && height <= maxSize) {
		scaleFactor := float64(maxSize) / float64(max(width, height))
		newWidth = int(float64(width) * scaleFactor)
		newHeight = int(float64(height) * scaleFactor)
	}
	
	thumbnail := image.NewRGBA(image.Rect(0, 0, newWidth, newHeight))
	originalBounds := img.Bounds()
	scaleX := float64(originalBounds.Dx()) / float64(newWidth)
	scaleY := float64(originalBounds.Dy()) / float64(newHeight)

	for x := 0; x < width; x++ {
		for y := 0; y < height; y++ {
			px := int(float64(x)*scaleX)
			py := int(float64(y)*scaleY)
			thumbnail.Set(x, y, img.At(px, py))
		}
	}

	return thumbnail
}

var ffmpegScriptPath string
var server_running bool
var currentDir string
var httpPort = flag.Int("port", 0, "Port can be anything from 1204 ~ 65535\nIt must not be 9990\n(default option: 7774)")
var isMode = flag.String("mode", "", "Select mode: none, both, send, receive\n(default option: none)")
var saveMedia = flag.Bool("save-media", false, "Save Media")
var autoDelete = flag.Bool("auto-delete-media", false, "Delete Downloaded Media After 30s")
//stop
'

sed -i -e "$(($(grep -nm 1 -F 'var cli *whatsmeow.Client' whatsmeow/mdtest/main.go | sed 's/:.*//')-1))r /dev/stdin" whatsmeow/mdtest/main.go <<< $code_body