#!/data/data/com.termux/files/usr/bin/bash

step_name="$(basename "$0" | sed -E 's/^[0-9]+\) //' | sed -E 's/\.sh$//')"
step_number="$(basename "$0" | grep -Eo '^[0-9]+')"
echo "$step_number) $step_name"

start_line=""
end_line=""
start_line="$(grep -nm 1 -F 'if evt.Message.GetPollUpdateMessage() != nil {' whatsmeow/mdtest/main.go | grep -Eo '^[0-9]+')"
end_line="$(wc -l whatsmeow/mdtest/main.go | grep -Eo "^[0-9]+")"
i="$start_line"

while (( $i < $end_line ))
do
    ((i++))
    if sed -n "${i}p" whatsmeow/mdtest/main.go | grep -q -F 'log.Infof("Saved image in message to %s", path)'
    then
    	while (( $i < $end_line ))
    	do
    	    ((i++))
            if sed -n "${i}p" whatsmeow/mdtest/main.go | grep -q '}'
            then
                sed -i "${start_line},${i}d" whatsmeow/mdtest/main.go
                break
            fi
        done
        break
    fi
done

code_body='
//start
var server *http.Server
var is_connected bool
var device_id string
var device_jid string
var default_jid string
var keepalive_timeout bool
var waitSync sync.WaitGroup
var groupInfo GroupInfo
var updatedGroupInfo bool

type Group struct {
	JID       string          `json:"JID"`
	Name      string          `json:"Name"`
}

type GroupInfo struct {
	Groups []Group `json:"groups"`
}

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

func parseReceivedMessage(evt *events.Message, wg *sync.WaitGroup) {
	defer wg.Done()
	for !updatedGroupInfo {
		time.Sleep(1 * time.Second)
		if updatedGroupInfo {
			break
		}
	}
	isSupported := false
	jsonData := "{}"
	path := ""
	port := fmt.Sprintf("%d", *httpPort)
	message_id := fmt.Sprintf("%s", evt.Info.ID)
	sender_pushname := fmt.Sprintf("%s", evt.Info.PushName)
	sender_jid := fmt.Sprintf("%s", evt.Info.Sender)
	receiver_jid := fmt.Sprintf("%s", evt.Info.Chat)
	time_stamp := ""
	parsedTime, err := time.Parse("2007-01-02 15:04:05 -0700 MST", fmt.Sprintf("%s", evt.Info.Timestamp))
	if err != nil {
		time_stamp = fmt.Sprintf("%d", time.Now().UTC().Unix())
	} else {
		time_stamp = fmt.Sprintf("%d", parsedTime.Unix())
	}
	is_from_myself := ""
	if evt.Info.MessageSource.IsFromMe {
		is_from_myself = "true"
	} else {
		is_from_myself = "false"
		if sender_jid == receiver_jid && default_jid != "" {
			receiver_jid = default_jid
		}
	}
	is_group := ""
	status_message := false
	group_name := ""
	if evt.Info.MessageSource.IsGroup && receiver_jid != "status@broadcast" {
		is_group = "true"
		for _, group := range groupInfo.Groups {
			if group.JID == receiver_jid {
				group_name = group.Name
				break
			}
		}
		
		if group_name != "" {
			jsonData, _ = AppendToJSON(jsonData, "group_name", group_name)
		} else {
			jsonData, _ = AppendToJSON(jsonData, "group_name", " Unknown, Group Not Found")
		}
	} else {
		is_group = "false"
	}
	if receiver_jid == "status@broadcast" {
		receiver_jid = default_jid
		status_message = true
	}
	jsonData, _ = AppendToJSON(jsonData, "port", port)
	jsonData, _ = AppendToJSON(jsonData, "sender_jid", sender_jid)
	jsonData, _ = AppendToJSON(jsonData, "receiver_jid", receiver_jid)
	jsonData, _ = AppendToJSON(jsonData, "sender_pushname", sender_pushname)
	jsonData, _ = AppendToJSON(jsonData, "is_from_myself", is_from_myself)
	jsonData, _ = AppendToJSON(jsonData, "is_group", is_group)
	jsonData, _ = AppendToJSON(jsonData, "time_stamp", time_stamp)
	
	if evt.Message.GetConversation() != "" {
		isSupported = true
		message := fmt.Sprintf("%s", evt.Message.GetConversation())
		
		jsonData, _ = AppendToJSON(jsonData, "type", "text_message")
		jsonData, _ = AppendToJSON(jsonData, "message", message)
		jsonData, _ = AppendToJSON(jsonData, "message_id", message_id)
	} else if evt.Message.GetExtendedTextMessage() != nil {
		if evt.Info.Type == "text" {
			isSupported = true
			message := fmt.Sprintf("%s", evt.Message.ExtendedTextMessage.GetText())
			if !status_message {
				jsonData, _ = AppendToJSON(jsonData, "type", "text_message")
			} else {
				jsonData, _ = AppendToJSON(jsonData, "type", "status_message")
			}
			jsonData, _ = AppendToJSON(jsonData, "message", message)
			jsonData, _ = AppendToJSON(jsonData, "message_id", message_id)
		} else if evt.Info.Type == "media" {
			msgData := evt.Message.GetExtendedTextMessage()
			if msgData.GetCanonicalUrl() != "" {
				isSupported = true
				message := fmt.Sprintf("%s", msgData.GetText())
				matched_text := fmt.Sprintf("%s", msgData.GetMatchedText())
				canonical_url := fmt.Sprintf("%s", msgData.GetCanonicalUrl())
				description := fmt.Sprintf("%s", msgData.GetDescription())
				title := fmt.Sprintf("%s", msgData.GetTitle())
				linkPreviewThumbnail := msgData.GetJpegThumbnail()
				if len(linkPreviewThumbnail) == 0 {
					log.Errorf("Failed to save link preview thumbnail: User cancelled it")
					return
				}
				os.MkdirAll(filepath.Join(currentDir, "media", "link"), os.ModePerm)
				path = filepath.Join(currentDir, "media", "link", fmt.Sprintf("%s.jpg", evt.Info.ID))
				err := os.WriteFile(path, linkPreviewThumbnail, 0644)
				if err != nil {
					log.Errorf("Failed to save link preview thumbnail: %v", err)
					return
				}
				log.Infof("Saved link preview thumbnail in message to %s", path)
				jsonData, _ = AppendToJSON(jsonData, "path", path)
				if !status_message {
					jsonData, _ = AppendToJSON(jsonData, "type", "link_message")
				} else {
					jsonData, _ = AppendToJSON(jsonData, "type", "status_message")
				}
				jsonData, _ = AppendToJSON(jsonData, "message", message)
				jsonData, _ = AppendToJSON(jsonData, "link_matched_text", matched_text)
				jsonData, _ = AppendToJSON(jsonData, "link_canonical_url", canonical_url)
				jsonData, _ = AppendToJSON(jsonData, "link_description", description)
				jsonData, _ = AppendToJSON(jsonData, "link_title", title)
				jsonData, _ = AppendToJSON(jsonData, "message_id", message_id)
			}
		}
	} else if evt.Message.GetButtonsResponseMessage() != nil {
		isSupported = true
		origin_message_id := fmt.Sprintf("%s", evt.Message.ButtonsResponseMessage.ContextInfo.GetStanzaId())
		button_selected_button := fmt.Sprintf("%s", evt.Message.ButtonsResponseMessage.GetSelectedDisplayText())
		button_title := fmt.Sprintf("%s", evt.Message.ButtonsResponseMessage.ContextInfo.QuotedMessage.ButtonsMessage.GetText())
		button_body := fmt.Sprintf("%s", evt.Message.ButtonsResponseMessage.ContextInfo.QuotedMessage.ButtonsMessage.GetContentText())
		button_footer := fmt.Sprintf("%s", evt.Message.ButtonsResponseMessage.ContextInfo.QuotedMessage.ButtonsMessage.GetFooterText())
		
		jsonData, _ = AppendToJSON(jsonData, "type", "button_response_message")
		jsonData, _ = AppendToJSON(jsonData, "button_selected_button", button_selected_button)
		jsonData, _ = AppendToJSON(jsonData, "button_title", button_title)
		jsonData, _ = AppendToJSON(jsonData, "button_body", button_body)
		jsonData, _ = AppendToJSON(jsonData, "button_footer", button_footer)
		jsonData, _ = AppendToJSON(jsonData, "origin_message_id", origin_message_id)
		jsonData, _ = AppendToJSON(jsonData, "message_id", message_id)
	} else if evt.Message.GetListResponseMessage() != nil {
		isSupported = true
		origin_message_id := fmt.Sprintf("%s", evt.Message.ListResponseMessage.ContextInfo.GetStanzaId())
		list_selected_title := fmt.Sprintf("%s", evt.Message.ListResponseMessage.GetTitle())
		list_selected_description := fmt.Sprintf("%s", evt.Message.ListResponseMessage.GetDescription())
		list_title := fmt.Sprintf("%s", evt.Message.ListResponseMessage.ContextInfo.QuotedMessage.ListMessage.GetTitle())
		list_body := fmt.Sprintf("%s", evt.Message.ListResponseMessage.ContextInfo.QuotedMessage.ListMessage.GetDescription())
		list_footer := fmt.Sprintf("%s", evt.Message.ListResponseMessage.ContextInfo.QuotedMessage.ListMessage.GetFooterText())
		list_button_text := fmt.Sprintf("%s", evt.Message.ListResponseMessage.ContextInfo.QuotedMessage.ListMessage.GetButtonText())
		list_header := fmt.Sprintf("%s", evt.Message.ListResponseMessage.ContextInfo.QuotedMessage.ListMessage.Sections[0].GetTitle())
		
		jsonData, _ = AppendToJSON(jsonData, "type", "list_response_message")
		jsonData, _ = AppendToJSON(jsonData, "list_selected_title", list_selected_title)
		jsonData, _ = AppendToJSON(jsonData, "list_selected_description", list_selected_description)
		jsonData, _ = AppendToJSON(jsonData, "list_title", list_title)
		jsonData, _ = AppendToJSON(jsonData, "list_body", list_body)
		jsonData, _ = AppendToJSON(jsonData, "list_footer", list_footer)
		jsonData, _ = AppendToJSON(jsonData, "list_body", list_body)
		jsonData, _ = AppendToJSON(jsonData, "list_button_text", list_button_text)
		jsonData, _ = AppendToJSON(jsonData, "list_header", list_header)
		jsonData, _ = AppendToJSON(jsonData, "message_id", message_id)
		jsonData, _ = AppendToJSON(jsonData, "origin_message_id", origin_message_id)
	} else if evt.Message.GetPollUpdateMessage() != nil {
		isSupported = true
		message_id = fmt.Sprintf("%s", evt.Message.PollUpdateMessage.PollCreationMessageKey.GetId())
		decrypted, err := cli.DecryptPollVote(evt)
		if err != nil {
			log.Errorf("Failed to decrypt vote: %v", err)
			return
		}
		
		questionData, err := os.ReadFile(filepath.Join(currentDir, ".tmp", "poll_question_" + message_id))
		if err != nil {
			log.Errorf("Failed to read question data: %v", err)
			return
		}
		
		question := string(questionData)
		
		selected_option := make([]interface{}, len(decrypted.SelectedOptions))
		
		for i, selectedOption := range decrypted.SelectedOptions {
			optionData, err := os.ReadFile(filepath.Join(currentDir, ".tmp", "poll_option_" + strings.ToLower(fmt.Sprintf("%X", selectedOption))))
			if err != nil {
				log.Errorf("Failed to read option data: %v", err)
				return
			}
			selected_option[i] = string(optionData)
		}
		jsonData, _ = AppendToJSON(jsonData, "type", "poll_response_message")
		jsonData, _ = AppendToJSON(jsonData, "poll_question", question)
		jsonData, _ = AppendToJSON(jsonData, "poll_selected_options", selected_option)
		jsonData, _ = AppendToJSON(jsonData, "message_id", message_id)
	} else if evt.Message.GetPollCreationMessage() != nil || evt.Message.GetPollCreationMessageV2() != nil || evt.Message.GetPollCreationMessageV3() != nil {
		os.MkdirAll(filepath.Join(currentDir, ".tmp"), os.ModePerm)
		
		if evt.Message.GetPollCreationMessage() != nil  {
			question := fmt.Sprintf("%s", evt.Message.PollCreationMessage.GetName())
			err := os.WriteFile(filepath.Join(currentDir, ".tmp", "poll_question_" + message_id), []byte(question), 0644)
			if err != nil {
				log.Errorf("Failed to save poll question: %v", err)
				return
			}
			
			for _, optionName := range evt.Message.PollCreationMessage.GetOptions() {
				option := strings.TrimPrefix(strings.TrimSuffix(fmt.Sprintf("%s", optionName), "\""), "optionName:\"")
				sha := fmt.Sprintf("%x", sha256.Sum256([]byte(option)))
				err := os.WriteFile(filepath.Join(currentDir, ".tmp", "poll_option_" + sha), []byte(option), 0644)
				if err != nil {
					log.Errorf("Failed to save poll option name and sha256sum: %v", err)
					return
				}
			}
		} else if evt.Message.GetPollCreationMessageV2() != nil {
			question := fmt.Sprintf("%s", evt.Message.PollCreationMessageV2.GetName())
			err := os.WriteFile(filepath.Join(currentDir, ".tmp", "poll_question_" + message_id), []byte(question), 0644)
			if err != nil {
				log.Errorf("Failed to save poll question: %v", err)
				return
			}
			
			for _, optionName := range evt.Message.PollCreationMessageV2.GetOptions() {
				option := strings.TrimPrefix(strings.TrimSuffix(fmt.Sprintf("%s", optionName), "\""), "optionName:\"")
				sha := fmt.Sprintf("%x", sha256.Sum256([]byte(option)))
				err := os.WriteFile(filepath.Join(currentDir, ".tmp", "poll_option_" + sha), []byte(option), 0644)
				if err != nil {
					log.Errorf("Failed to save poll option name and sha256sum: %v", err)
					return
				}
			}
		} else if evt.Message.GetPollCreationMessageV3() != nil {
			question := fmt.Sprintf("%s", evt.Message.PollCreationMessageV3.GetName())
			err := os.WriteFile(filepath.Join(currentDir, ".tmp", "poll_question_" + message_id), []byte(question), 0644)
			if err != nil {
				log.Errorf("Failed to save poll question: %v", err)
				return
			}
			
			for _, optionName := range evt.Message.PollCreationMessageV3.GetOptions() {
				option := strings.TrimPrefix(strings.TrimSuffix(fmt.Sprintf("%s", optionName), "\""), "optionName:\"")
				sha := fmt.Sprintf("%x", sha256.Sum256([]byte(option)))
				err := os.WriteFile(filepath.Join(currentDir, ".tmp", "poll_option_" + sha), []byte(option), 0644)
				if err != nil {
					log.Errorf("Failed to save poll option name and sha256sum: %v", err)
					return
				}
			}
		}
	} else if *saveMedia {
		if evt.Message.GetLocationMessage() != nil {
			
			isSupported = true
			jsonData, _ = AppendToJSON(jsonData, "type", "location_message")
			jsonData, _ = AppendToJSON(jsonData, "message_id", message_id)
			locData := evt.Message.GetLocationMessage()
			latitude := fmt.Sprintf("%f", locData.GetDegreesLatitude())
			longitude := fmt.Sprintf("%f", locData.GetDegreesLongitude())
			jsonData, _ = AppendToJSON(jsonData, "location_latitude", latitude)
			jsonData, _ = AppendToJSON(jsonData, "location_longitude", longitude)
			locThumbnail := locData.GetJpegThumbnail()
			if len(locThumbnail) == 0 {
				log.Errorf("Failed to save location thumbnail: User cancelled it")
				return
			}
			os.MkdirAll(filepath.Join(currentDir, "media", "location"), os.ModePerm)
			path = filepath.Join(currentDir, "media", "location", fmt.Sprintf("%s.jpg", evt.Info.ID))
			err := os.WriteFile(path, locThumbnail, 0644)
			if err != nil {
				log.Errorf("Failed to save location thumbnail: %v", err)
				return
			}
			log.Infof("Saved location thumbnail in message to %s", path)
			jsonData, _ = AppendToJSON(jsonData, "path", path)
		} else if evt.Message.GetLiveLocationMessage() != nil {
			
			isSupported = true
			jsonData, _ = AppendToJSON(jsonData, "type", "location_message")
			jsonData, _ = AppendToJSON(jsonData, "message_id", message_id)
			locData := evt.Message.GetLiveLocationMessage()
			caption := locData.GetCaption()
			if caption != "" {
				jsonData, _ = AppendToJSON(jsonData, "message", caption)
			}
			latitude := fmt.Sprintf("%f", locData.GetDegreesLatitude())
			longitude := fmt.Sprintf("%f", locData.GetDegreesLongitude())
			jsonData, _ = AppendToJSON(jsonData, "location_latitude", latitude)
			jsonData, _ = AppendToJSON(jsonData, "location_longitude", longitude)
			locThumbnail := locData.GetJpegThumbnail()
			if len(locThumbnail) == 0 {
				log.Errorf("Failed to save location thumbnail: User cancelled it")
				return
			}
			os.MkdirAll(filepath.Join(currentDir, "media", "location"), os.ModePerm)
			path = filepath.Join(currentDir, "media", "location", fmt.Sprintf("%s.jpg", evt.Info.ID))
			err := os.WriteFile(path, locThumbnail, 0644)
			if err != nil {
				log.Errorf("Failed to save location thumbnail: %v", err)
				return
			}
			log.Infof("Saved location thumbnail in message to %s", path)
			jsonData, _ = AppendToJSON(jsonData, "path", path)
		} else if evt.Message.GetContactsArrayMessage() != nil {
			
			isSupported = true
			jsonData, _ = AppendToJSON(jsonData, "type", "contact_message")
			jsonData, _ = AppendToJSON(jsonData, "message_id", message_id)
			os.MkdirAll(filepath.Join(currentDir, "media", "contact"), os.ModePerm)
			contactData := evt.Message.GetContactsArrayMessage()
			for i, contactInfo  := range contactData.GetContacts() {
				display_name := fmt.Sprintf("%s", contactInfo.GetDisplayName())
				jsonData, _ = AppendToJSON(jsonData, "contact_display_name", display_name)
				vcard := fmt.Sprintf("%s", contactInfo.GetVcard())
				pathTmp := filepath.Join(currentDir, "media", "contact", fmt.Sprintf("%s-%d.vcf", evt.Info.ID, i+1))
				err := os.WriteFile(pathTmp, []byte(vcard), 0644)
				if err != nil {
					log.Errorf("Failed to save vcard: %v", err)
				} else {
					log.Infof("Saved vcard in message to %s", pathTmp)
					jsonData, _ = AppendToJSON(jsonData, "path", pathTmp)
					if isSupported {
						log.Infof("%s", jsonData)
						//http
						httpPath := "/message"
						go sendHttpPost(jsonData, httpPath)
					}
					if *autoDelete {
						go func() {
							if pathTmp != "" {
								time.Sleep(30 * time.Second)
								os.Remove(pathTmp)
							}
						}()
					}
				}
			}
			return
		} else if evt.Message.GetContactMessage() != nil {
			
			isSupported = true
			jsonData, _ = AppendToJSON(jsonData, "type", "contact_message")
			jsonData, _ = AppendToJSON(jsonData, "message_id", message_id)
			display_name := fmt.Sprintf("%s", evt.Message.ContactMessage.GetDisplayName())
			vcard := fmt.Sprintf("%s", evt.Message.ContactMessage.GetVcard())
			jsonData, _ = AppendToJSON(jsonData, "contact_display_name", display_name)
			os.MkdirAll(filepath.Join(currentDir, "media", "contact"), os.ModePerm)
			path = filepath.Join(currentDir, "media", "contact", fmt.Sprintf("%s.vcf", evt.Info.ID))
			err := os.WriteFile(path, []byte(vcard), 0644)
			if err != nil {
				log.Errorf("Failed to save vcard: %v", err)
				return
			}
			log.Infof("Saved vcard in message to %s", path)
			jsonData, _ = AppendToJSON(jsonData, "path", path)
		} else if evt.Message.GetImageMessage() != nil {
			isSupported = true
			jsonData, _ = AppendToJSON(jsonData, "message_id", message_id)
			imgData := evt.Message.GetImageMessage()
			caption := imgData.GetCaption()
			if caption != "" {
				jsonData, _ = AppendToJSON(jsonData, "message", caption)
			}
			data, err := cli.Download(imgData)
			if err != nil {
				log.Errorf("Failed to download image: %v", err)
				return
			}
			mimeType := mimemagic.MatchMagic(data)
			if status_message {
				jsonData, _ = AppendToJSON(jsonData, "type", "status_message")
				os.MkdirAll(filepath.Join(currentDir, "media", "status"), os.ModePerm)
				if len(mimeType.Extensions) == 0 {
					path = filepath.Join(currentDir, "media", "status", fmt.Sprintf("%s.tmp", evt.Info.ID))
					err = os.WriteFile(path, data, 0644)
					if err != nil {
						log.Errorf("Failed to save status: %v", err)
						return
					}
					log.Errorf("Status message extension unknown, saving as %s", path)
				} else {
					path = filepath.Join(currentDir, "media", "status", fmt.Sprintf("%s%s", evt.Info.ID, mimeType.Extensions[0]))
					err = os.WriteFile(path, data, 0644)
					if err != nil {
						log.Errorf("Failed to save status: %v", err)
						return
					}
					log.Infof("Saved status in message to %s", path)
				}
			} else {
				jsonData, _ = AppendToJSON(jsonData, "type", "image_message")
				os.MkdirAll(filepath.Join(currentDir, "media", "image"), os.ModePerm)
				if len(mimeType.Extensions) == 0 {
					path = filepath.Join(currentDir, "media", "image", fmt.Sprintf("%s.tmp", evt.Info.ID))
					err = os.WriteFile(path, data, 0644)
					if err != nil {
						log.Errorf("Failed to save image: %v", err)
						return
					}
					log.Errorf("Image message extension unknown, saving as %s", path)
				} else {
					path = filepath.Join(currentDir, "media", "image", fmt.Sprintf("%s%s", evt.Info.ID, mimeType.Extensions[0]))
					err = os.WriteFile(path, data, 0644)
					if err != nil {
						log.Errorf("Failed to save image: %v", err)
						return
					}
					log.Infof("Saved image in message to %s", path)
				}
			}
			jsonData, _ = AppendToJSON(jsonData, "path", path)
		} else if evt.Message.GetVideoMessage() != nil {
			isSupported = true
			jsonData, _ = AppendToJSON(jsonData, "message_id", message_id)
			vidData := evt.Message.GetVideoMessage()
			isGif := false
			if evt.Info.MediaType == "gif" {
				isGif = true
			}
			caption := vidData.GetCaption()
			if caption != "" {
				jsonData, _ = AppendToJSON(jsonData, "message", caption)
			}
			data, err := cli.Download(vidData)
			if err != nil {
				log.Errorf("Failed to download video: %v", err)
				return
			}
			mimeType := mimemagic.MatchMagic(data)
			if status_message {
				jsonData, _ = AppendToJSON(jsonData, "type", "status_message")
				os.MkdirAll(filepath.Join(currentDir, "media", "status"), os.ModePerm)
				if isGif {
					path = filepath.Join(currentDir, "media", "status", fmt.Sprintf("%s.gif", evt.Info.ID))
					err = os.WriteFile(path, data, 0644)
					if err != nil {
						log.Errorf("Failed to save status: %v", err)
						return
					}
					log.Infof("Saved status in message to %s", path)
				} else if len(mimeType.Extensions) == 0 {
					path = filepath.Join(currentDir, "media", "status", fmt.Sprintf("%s.tmp", evt.Info.ID))
					err = os.WriteFile(path, data, 0644)
					if err != nil {
						log.Errorf("Failed to save status: %v", err)
						return
					}
					log.Errorf("Status message extension unknown, saving as %s", path)
				} else {
					path = filepath.Join(currentDir, "media", "status", fmt.Sprintf("%s%s", evt.Info.ID, mimeType.Extensions[0]))
					err = os.WriteFile(path, data, 0644)
					if err != nil {
						log.Errorf("Failed to save status: %v", err)
						return
					}
					log.Infof("Saved status in message to %s", path)
				}
			} else {
				jsonData, _ = AppendToJSON(jsonData, "type", "video_message")
				os.MkdirAll(filepath.Join(currentDir, "media", "video"), os.ModePerm)
				if isGif {
					path = filepath.Join(currentDir, "media", "video", fmt.Sprintf("%s.gif", evt.Info.ID))
					err = os.WriteFile(path, data, 0644)
					if err != nil {
						log.Errorf("Failed to save status: %v", err)
						return
					}
					log.Infof("Saved video in message to %s", path)
				} else if len(mimeType.Extensions) == 0 {
					path = filepath.Join(currentDir, "media", "video", fmt.Sprintf("%s.tmp", evt.Info.ID))
					err = os.WriteFile(path, data, 0644)
					if err != nil {
						log.Errorf("Failed to save video: %v", err)
						return
					}
					log.Errorf("Video message extension unknown, saving as %s", path)
				} else {
					path = filepath.Join(currentDir, "media", "video", fmt.Sprintf("%s%s", evt.Info.ID, mimeType.Extensions[0]))
					err = os.WriteFile(path, data, 0644)
					if err != nil {
						log.Errorf("Failed to save video: %v", err)
						return
					}
					log.Infof("Saved video in message to %s", path)
				}
			}
			jsonData, _ = AppendToJSON(jsonData, "path", path)
		} else if evt.Message.GetDocumentMessage() != nil {
			isSupported = true
			jsonData, _ = AppendToJSON(jsonData, "type", "document_message")
			jsonData, _ = AppendToJSON(jsonData, "message_id", message_id)
			docData := evt.Message.GetDocumentMessage()
			caption := docData.GetCaption()
			if caption != "" {
				jsonData, _ = AppendToJSON(jsonData, "message", caption)
			}
			file_name := docData.GetFileName()
			if file_name != "" {
				jsonData, _ = AppendToJSON(jsonData, "document_file_name", file_name)
			}
			data, err := cli.Download(docData)
			if err != nil {
				log.Errorf("Failed to download document: %v", err)
				return
			}
			mimeType := mimemagic.MatchMagic(data)
			os.MkdirAll(filepath.Join(currentDir, "media", "document"), os.ModePerm)
			if len(mimeType.Extensions) == 0 {
				path = filepath.Join(currentDir, "media", "document", fmt.Sprintf("%s.tmp", evt.Info.ID))
				err = os.WriteFile(path, data, 0644)
				if err != nil {
					log.Errorf("Failed to save document: %v", err)
					return
				}
				log.Errorf("Document message extension unknown, saving as %s", path)
			} else {
				path = filepath.Join(currentDir, "media", "document", fmt.Sprintf("%s%s", evt.Info.ID, mimeType.Extensions[0]))
				err = os.WriteFile(path, data, 0644)
				if err != nil {
					log.Errorf("Failed to save document: %v", err)
					return
				}
				log.Infof("Saved document in message to %s", path)
			}
			jsonData, _ = AppendToJSON(jsonData, "path", path)
		} else if evt.Message.GetAudioMessage() != nil {
			isSupported = true
			jsonData, _ = AppendToJSON(jsonData, "type", "audio_message")
			jsonData, _ = AppendToJSON(jsonData, "message_id", message_id)
			audioData := evt.Message.GetAudioMessage()
			data, err := cli.Download(audioData)
			if err != nil {
				log.Errorf("Failed to download audio: %v", err)
				return
			}
			mimeType := mimemagic.MatchMagic(data)
			os.MkdirAll(filepath.Join(currentDir, "media", "audio"), os.ModePerm)
			if len(mimeType.Extensions) == 0 {
				path = filepath.Join(currentDir, "media", "audio", fmt.Sprintf("%s.tmp", evt.Info.ID))
				err = os.WriteFile(path, data, 0644)
				if err != nil {
					log.Errorf("Failed to save audio: %v", err)
					return
				}
				log.Errorf("Audio message extension unknown, saving as %s", path)
			} else {
				if mimeType.Extensions[0] == ".ogg" || mimeType.Extensions[0] == ".oga" {
					path = filepath.Join(currentDir, "media", "audio", fmt.Sprintf("%s.ogg", evt.Info.ID))
					err = os.WriteFile(path, data, 0644)
					if err != nil {
						log.Errorf("Failed to save audio: %v", err)
						return
					}
					log.Infof("Saved audio in message to %s", path)
				} else {
					path = filepath.Join(currentDir, "media", "audio", fmt.Sprintf("%s%s", evt.Info.ID, mimeType.Extensions[0]))
					err = os.WriteFile(path, data, 0644)
					if err != nil {
						log.Errorf("Failed to save audio: %v", err)
						return
					}
					log.Infof("Saved audio in message to %s", path)
				}
			}
			jsonData, _ = AppendToJSON(jsonData, "path", path)
		}
	}
	if isSupported {
		log.Infof("%s", jsonData)
		//http
		httpPath := "/message"
		go sendHttpPost(jsonData, httpPath)
	}
	if *autoDelete {
		go func() {
			if path != "" {
				time.Sleep(30 * time.Second)
				os.Remove(path)
			}
		}()
	}
	if evt.Message.GetPollUpdateMessage() != nil {
		decrypted, err := cli.DecryptPollVote(evt)
		if err != nil {
			log.Errorf("Failed to decrypt vote: %v", err)
		} else {
			log.Infof("Selected options in decrypted vote:")
			for _, option := range decrypted.SelectedOptions {
				log.Infof("- %X", option)
			}
		}
	} else if evt.Message.GetEncReactionMessage() != nil {
		decrypted, err := cli.DecryptReaction(evt)
		if err != nil {
			log.Errorf("Failed to decrypt encrypted reaction: %v", err)
		} else {
			log.Infof("Decrypted reaction: %+v", decrypted)
		}
	}
}

var ffmpegScriptPath string
var server_running bool
var currentDir string
var httpPort = flag.Int("port", 0, "Port can be anything from 1024 ~ 65535\nIt must not be 9990\n(default option: 7774)")
var isMode = flag.String("mode", "none", "Select mode: none, both, send\n(default option: none)")
var saveMedia = flag.Bool("save-media", false, "Save Media")
var autoDelete = flag.Bool("auto-delete-media", false, "Delete Downloaded Media After 30s")
//stop
'

sed -i -e "$(($(grep -nm 1 -F 'var cli *whatsmeow.Client' whatsmeow/mdtest/main.go | sed 's/:.*//')-1))r /dev/stdin" whatsmeow/mdtest/main.go <<< $code_body
