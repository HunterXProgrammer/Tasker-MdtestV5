#!/data/data/com.termux/files/usr/bin/bash

step_name="$(basename "$0" | sed -E 's/^[0-9]+\) //' | sed -E 's/\.sh$//')"
step_number="$(basename "$0" | grep -Eo '^[0-9]+')"
echo "$step_number) $step_name"

code_body='
			//start
			"type": strings.ToLower(waProto.ListMessage_ListType_name[int32(*waProto.ListMessage_PRODUCT_LIST.Enum())]),
			//stop
'

sed -i -e "$(grep -nm 1 -F '"type": strings.ToLower(waProto.ListMessage_ListType_name[int32(msg.ListMessage.GetListType())]),' whatsmeow/send.go | sed 's/:.*//')r /dev/stdin" whatsmeow/send.go <<< $code_body

sed -i '/"type": strings.ToLower(waProto.ListMessage_ListType_name\[int32(msg.ListMessage.GetListType())\]),/d' whatsmeow/send.go

code_body='
	//start
	case "sendlist":
		if len(args) < 9 {
			log.Errorf("Usage: sendlist <jid> <title> <text> <footer> <button text> <sub title> -- <heading 1> <description 1> / ...")
			return
		}
		recipient, ok := parseJID(args[0])
		if !ok {
			return
		}
		
		if args[6] != "--" {
			log.Errorf("Missing -- seperator")
			log.Errorf("Usage: sendlist <jid> <title> <text> <footer> <button text> <sub title> -- <heading 1> <description 1> / ...")
			return
		}
		
		msg := &waProto.Message{
			ListMessage: &waProto.ListMessage{
				Title:       proto.String(args[1]),
				Description: proto.String(args[2]),
				FooterText:  proto.String(args[3]),
				ButtonText:  proto.String(args[4]),
				ListType:    waProto.ListMessage_SINGLE_SELECT.Enum(),
				Sections: []*waProto.ListMessage_Section{
					{
						Title: proto.String(args[5]),
						Rows:  []*waProto.ListMessage_Row{},
					},
				},
			},
		}
		
		items := args[7:]
		
		itemTmp := ""
		for i, _ := range items {
			if (i+1)%3 == 0 {
				if items[i] != "/" {
					log.Errorf("Error at \"%s\"", items[i])
					log.Errorf("Seperator \"/\" is missing")
					return
				} else if len(items)!= 2 && i+1 == len(items) {
					log.Errorf("Missing items after \"/\"")
					return
				}
			} else if i%3 == 0 {
				itemTmp = items[i]
				if i+1 == len(items) {
					log.Errorf("Error at \"%s\"", items[i])
					log.Errorf("Missing description after heading")
					return
				}
			} else if (i+2)%3 == 0 {
				newRow := &waProto.ListMessage_Row{
			        RowId:       proto.String(fmt.Sprintf("id%d", i+1)),
					Title:       proto.String(itemTmp),
					Description: proto.String(items[i]),
			    }
			    msg.ListMessage.Sections[0].Rows = append(msg.ListMessage.Sections[0].Rows, newRow)
				if i+1 == len(items) {
					break
				}
			}
		}
		resp, err := cli.SendMessage(context.Background(), recipient, msg)
		if err != nil {
			log.Errorf("Error sending message: %v", err)
		} else {
			log.Infof("List message sent (server timestamp: %s)", resp.Timestamp)
		}
	case "listusers":
		users, err := cli.Store.Contacts.GetAllContacts()
		if err != nil {
			log.Errorf("Failed to get user list: %v", err)
		} else {
			type User struct {
				Found        bool   `json:"Found"`
				FirstName    string `json:"FirstName"`
				FullName     string `json:"FullName"`
				PushName     string `json:"PushName"`
				BusinessName string `json:"BusinessName"`
			}
			jids := make([]string, 0, len(users))
			for jid := range users {
				jids = append(jids, fmt.Sprintf("%s", jid))
			}
			output := struct {
				Jids  []string `json:"jids"`
				Users map[types.JID]types.ContactInfo `json:"users"`
			}{
				Jids:  jids,
				Users: users,
			}
			jsonContent, err := json.MarshalIndent(output, "", "  ")
			if err != nil {
				fmt.Println(err)
				return
			}
			fmt.Print(string(jsonContent))
		}
	case "listgroups":
		groups, err := cli.GetJoinedGroups()
		if err != nil {
			log.Errorf("Failed to get group list: %v", err)
		} else {
			jsonContent, err := json.MarshalIndent(groups, "", "  ")
			if err != nil {
				fmt.Println(err)
 	   		return
			}
			result := make(map[string]interface{})
			result["groups"] = json.RawMessage(jsonContent)
			output, err := json.MarshalIndent(result, "", "  ")
			if err != nil {
				fmt.Println(err)
	    		return
			}
			fmt.Print(string(output))
		}
	case "sendpoll":
		if len(args) < 7 {
			log.Errorf("Usage: sendpoll <jid> <max answers> <question> -- <option 1> / <option 2> / ...")
			return
		}
		recipient, ok := parseJID(args[0])
		if !ok {
			return
		}
		maxAnswers, err := strconv.Atoi(args[1])
		if err != nil {
			log.Errorf("Number of max answers must be an integer")
			return
		}
		remainingArgs := strings.Join(args[2:], " ")
		question, optionsStr, _ := strings.Cut(remainingArgs, "--")
		question = strings.TrimSpace(question)
		options := strings.Split(optionsStr, "/")
		if *isMode == "both" {
			os.MkdirAll(filepath.Join(currentDir, ".tmp"), os.ModePerm)
			msgID := whatsmeow.GenerateMessageID()
			err := os.WriteFile(filepath.Join(currentDir, ".tmp", "poll_question_" + msgID), []byte(question), 0644)
			if err != nil {
				log.Errorf("Failed to save poll question: %v", err)
				return
			}
			
			for _, option := range options {
				sha := fmt.Sprintf("%x", sha256.Sum256([]byte(option)))
				err := os.WriteFile(filepath.Join(currentDir, ".tmp", "poll_option_" + sha), []byte(option), 0644)
				if err != nil {
					log.Errorf("Failed to save poll option name and sha256sum: %v", err)
					return
				}
			}
			resp, err := cli.SendMessage(context.Background(), recipient, cli.BuildPollCreation(question, options, maxAnswers), whatsmeow.SendRequestExtra{ID: msgID})
			if err != nil {
				log.Errorf("Error sending message: %v", err)
			} else {
				log.Infof("Poll message sent (server timestamp: %s)", resp.Timestamp)
			}
			return
		}
		resp, err := cli.SendMessage(context.Background(), recipient, cli.BuildPollCreation(question, options, maxAnswers))
		if err != nil {
			log.Errorf("Error sending message: %v", err)
		} else {
			log.Infof("Poll message sent (server timestamp: %s)", resp.Timestamp)
		}
	case "sendlink":
		if len(args) < 2 {
			log.Errorf("Usage: sendlink <jid> <url/link> [text]")
			return
		}
		recipient, ok := parseJID(args[0])
		if !ok {
			return
		}
		
		text := ""
		
		if len(args) > 2 {
			text = fmt.Sprintf("\n\n") + strings.Join(args[2:], " ")
		}
		
		ogp, err := opengraph.Fetch(args[1])
		if err != nil {
			log.Errorf("Could not fetch Open Graph data: %s", err)
			msg := &waProto.Message{ExtendedTextMessage: &waProto.ExtendedTextMessage{
				Text:          proto.String(args[1] + text),
				CanonicalUrl:  proto.String(args[1]),
				MatchedText:   proto.String(args[1]),
			}}
			resp, err := cli.SendMessage(context.Background(), recipient, msg)
			if err != nil {
				log.Errorf("Error sending link message: %v", err)
		    } else {
		    	log.Infof("Link message sent (server timestamp: %s)", resp.Timestamp)
		    }
		    return
		}
		
		ogp.ToAbs()
		
		if ! (ogp.Title != "" && ogp.Description != "" && (len(ogp.Image) > 0 && ogp.Image[0].URL != "")) {
			log.Errorf("Could not fetch Open Graph data: Missing Open Graph content")
			msg := &waProto.Message{ExtendedTextMessage: &waProto.ExtendedTextMessage{
					Text:          proto.String(args[1] + text),
					CanonicalUrl:  proto.String(args[1]),
					MatchedText:   proto.String(args[1]),
				}}
				
			resp, err := cli.SendMessage(context.Background(), recipient, msg)
			if err != nil {
				log.Errorf("Error sending link message: %v", err)
		    } else {
		    	log.Infof("Link message sent (server timestamp: %s)", resp.Timestamp)
		    }
			return
		}
		
		data, err := http.Get(ogp.Image[0].URL)
		if err != nil {
			log.Errorf("Could not fetch thumbnail data: %s", err)
			return
		}
	
		if data.StatusCode != http.StatusOK {
			log.Errorf("Could not fetch thumbnail data: %d\n", data.StatusCode)
			return
		}
	
		jpegBytes, err := ioutil.ReadAll(data.Body)
		if err != nil {
			log.Errorf("Could not fetch thumbnail data: %s", err)
			return
		}
		data.Body.Close()
		
		config, _, err := image.DecodeConfig(bytes.NewReader(jpegBytes))
		if err != nil {
			log.Errorf("Could not decode image: %s", err)
			err := error(nil)
			thumbnailResp := whatsmeow.UploadResponse{}
			if recipient.Server == types.NewsletterServer {
				thumbnailResp, err = cli.UploadNewsletter(context.Background(), jpegBytes, whatsmeow.MediaLinkThumbnail)
			} else {
				thumbnailResp, err = cli.Upload(context.Background(), jpegBytes, whatsmeow.MediaLinkThumbnail)
			}
			//thumbnailResp, err := cli.Upload(context.Background(), jpegBytes, whatsmeow.MediaLinkThumbnail)
			if err != nil {
				log.Errorf("Failed to upload preview thumbnail file: %v", err)
				return
			}
			
			msg := &waProto.Message{ExtendedTextMessage: &waProto.ExtendedTextMessage{
					Text:          proto.String(args[1] + text),
					Title:         proto.String(ogp.Title),
					CanonicalUrl:  proto.String(args[1]),
					MatchedText:   proto.String(args[1]),
					Description:   proto.String(ogp.Description),
					JpegThumbnail: jpegBytes,
					ThumbnailDirectPath: &thumbnailResp.DirectPath,
					ThumbnailSha256: thumbnailResp.FileSHA256,
					ThumbnailEncSha256: thumbnailResp.FileEncSHA256,
					MediaKey:      thumbnailResp.MediaKey,
				}}
				
			resp, err := cli.SendMessage(context.Background(), recipient, msg)
			if err != nil {
				log.Errorf("Error sending link message: %v", err)
		    } else {
		    	log.Infof("Link message sent (server timestamp: %s)", resp.Timestamp)
		    }
		} else {
			err := error(nil)
			thumbnailResp := whatsmeow.UploadResponse{}
			if recipient.Server == types.NewsletterServer {
				thumbnailResp, err = cli.UploadNewsletter(context.Background(), jpegBytes, whatsmeow.MediaLinkThumbnail)
			} else {
				thumbnailResp, err = cli.Upload(context.Background(), jpegBytes, whatsmeow.MediaLinkThumbnail)
			}
			//thumbnailResp, err := cli.Upload(context.Background(), jpegBytes, whatsmeow.MediaLinkThumbnail)
			if err != nil {
				log.Errorf("Failed to upload preview thumbnail file: %v", err)
				return
			}
			
			msg := &waProto.Message{ExtendedTextMessage: &waProto.ExtendedTextMessage{
					Text:          proto.String(args[1] + text),
					Title:         proto.String(ogp.Title),
					CanonicalUrl:  proto.String(args[1]),
					MatchedText:   proto.String(args[1]),
					Description:   proto.String(ogp.Description),
					JpegThumbnail: jpegBytes,
					ThumbnailDirectPath: &thumbnailResp.DirectPath,
					ThumbnailSha256: thumbnailResp.FileSHA256,
					ThumbnailEncSha256: thumbnailResp.FileEncSHA256,
					ThumbnailWidth:  proto.Uint32(uint32(config.Width)),
					ThumbnailHeight:  proto.Uint32(uint32(config.Height)),
					MediaKey:      thumbnailResp.MediaKey,
				}}
				
			resp, err := cli.SendMessage(context.Background(), recipient, msg)
			if err != nil {
				log.Errorf("Error sending link message: %v", err)
		    } else {
		    	log.Infof("Link message sent (server timestamp: %s)", resp.Timestamp)
		    }
		}
	case "senddoc":
		if len(args) < 3 {
			log.Errorf("Usage: senddoc <jid> <document path> <document file name> [caption] [mime-type]")
			return
		}
		recipient, ok := parseJID(args[0])
		if !ok {
			return
		}
		data, err := os.ReadFile(args[1])
		if err != nil {
			log.Errorf("Failed to read %s: %v", args[1], err)
			return
		}
		uploaded := whatsmeow.UploadResponse{}
		if recipient.Server == types.NewsletterServer {
			uploaded, err = cli.UploadNewsletter(context.Background(), data, whatsmeow.MediaDocument)
		} else {
			uploaded, err = cli.Upload(context.Background(), data, whatsmeow.MediaDocument)
		}
		//uploaded, err := cli.Upload(context.Background(), data, whatsmeow.MediaDocument)
		if err != nil {
			log.Errorf("Failed to upload file: %v", err)
			return
		}
		caption := ""
		if len(args) > 3 && args[3] != "" {
			caption = args[3]
		}
		if len(args) < 5 {
			msg := &waProto.Message{DocumentMessage: &waProto.DocumentMessage{
				Title:         proto.String(args[2]),
				Caption:       proto.String(caption),
				Url:           proto.String(uploaded.URL),
				DirectPath:    proto.String(uploaded.DirectPath),
				MediaKey:      uploaded.MediaKey,
				Mimetype:      proto.String(http.DetectContentType(data)),
				FileEncSha256: uploaded.FileEncSHA256,
				FileSha256:    uploaded.FileSHA256,
				FileLength:    proto.Uint64(uint64(len(data))),
			}}
			resp, err := cli.SendMessage(context.Background(), recipient, msg)
			if err != nil {
				log.Errorf("Error sending document message: %v", err)
			} else {
				log.Infof("Document message sent (server timestamp: %s)", resp.Timestamp)
			}
		} else {
			msg := &waProto.Message{DocumentMessage: &waProto.DocumentMessage{
				Title:         proto.String(args[2]),
				Caption:       proto.String(caption),
				Url:           proto.String(uploaded.URL),
				DirectPath:    proto.String(uploaded.DirectPath),
				MediaKey:      uploaded.MediaKey,
				Mimetype:      proto.String(args[4]),
				FileEncSha256: uploaded.FileEncSHA256,
				FileSha256:    uploaded.FileSHA256,
				FileLength:    proto.Uint64(uint64(len(data))),
			}}
			resp, err := cli.SendMessage(context.Background(), recipient, msg)
		    if err != nil {
			    log.Errorf("Error sending document message: %v", err)
		    } else {
			    log.Infof("Document message sent (server timestamp: %s)", resp.Timestamp)
		    }
		}
	
	case "sendvid":
		if len(args) < 2 {
			log.Errorf("Usage: sendvid <jid> <video path> [caption]")
			return
		}
		recipient, ok := parseJID(args[0])
		if !ok {
			return
		}
		
		data, err := os.ReadFile(args[1])
		if err != nil {
			log.Errorf("Failed to read %s: %v", args[1], err)
			return
		}
		
		outBuf := new(bytes.Buffer)
		
		command := []string{
			ffmpegScriptPath,
			"-y",
			"-i", args[1],
			"-hide_banner",
			"-nostats",
			"-loglevel", "0",
			"-vframes", "1",
			"-q:v", "0",
			"-f", "mjpeg",
			"pipe:1",
		}
		
		cmd := exec.Command("sh", command...)
		cmd.Stdout = outBuf
		
		err = cmd.Run()
		if err != nil {
			log.Errorf("Error while using ffmpeg to create thumbnail: %s", err)
			log.Errorf("Sending video without preview thumbnail")
			err := error(nil)
			uploaded := whatsmeow.UploadResponse{}
			if recipient.Server == types.NewsletterServer {
				uploaded, err = cli.UploadNewsletter(context.Background(), data, whatsmeow.MediaVideo)
			} else {
				uploaded, err = cli.Upload(context.Background(), data, whatsmeow.MediaVideo)
			}
			//uploaded, err := cli.Upload(context.Background(), data, whatsmeow.MediaVideo)
			if err != nil {
				log.Errorf("Failed to upload file: %v", err)
				return
			}
			msg := &waProto.Message{VideoMessage: &waProto.VideoMessage{
				Caption:       proto.String(strings.Join(args[2:], " ")),
				Url:           proto.String(uploaded.URL),
				DirectPath:    proto.String(uploaded.DirectPath),
				MediaKey:      uploaded.MediaKey,
				Mimetype:      proto.String(http.DetectContentType(data)),
				FileEncSha256: uploaded.FileEncSHA256,
				FileSha256:    uploaded.FileSHA256,
				FileLength:    proto.Uint64(uint64(len(data))),
			}}
			resp, err := cli.SendMessage(context.Background(), recipient, msg)
			if err != nil {
				log.Errorf("Error sending video message: %v", err)
			} else {
				log.Infof("Video message sent (server timestamp: %s)", resp.Timestamp)
			}
			return
		}
		
		img, _, err := image.Decode(outBuf)
		if err != nil {
			log.Errorf("Error decoding image: %s", err)
			return
		}
		
		thumbnail := resizeImage(img)
		
		buffer := new(bytes.Buffer)
		
		err = jpeg.Encode(buffer, thumbnail, nil)
		if err != nil {
			log.Errorf("Error encoding thumbnail: %s", err)
			return
		}
		
		jpegBytes := buffer.Bytes()
		
		uploaded := whatsmeow.UploadResponse{}
		if recipient.Server == types.NewsletterServer {
			uploaded, err = cli.UploadNewsletter(context.Background(), data, whatsmeow.MediaVideo)
		} else {
			uploaded, err = cli.Upload(context.Background(), data, whatsmeow.MediaVideo)
		}
		//uploaded, err := cli.Upload(context.Background(), data, whatsmeow.MediaVideo)
		if err != nil {
			log.Errorf("Failed to upload file: %v", err)
			return
		}
		thumbnailResp := whatsmeow.UploadResponse{}
		if recipient.Server == types.NewsletterServer {
			thumbnailResp, err = cli.UploadNewsletter(context.Background(), jpegBytes, whatsmeow.MediaImage)
		} else {
			thumbnailResp, err = cli.Upload(context.Background(), jpegBytes, whatsmeow.MediaImage)
		}
		//thumbnailResp, err := cli.Upload(context.Background(), jpegBytes, whatsmeow.MediaImage)
		if err != nil {
			log.Errorf("Failed to upload preview thumbnail file: %v", err)
			return
		}
		
		msg := &waProto.Message{VideoMessage: &waProto.VideoMessage{
			Caption:       proto.String(strings.Join(args[2:], " ")),
			Url:           proto.String(uploaded.URL),
			DirectPath:    proto.String(uploaded.DirectPath),
			ThumbnailDirectPath: &thumbnailResp.DirectPath,
			ThumbnailSha256: thumbnailResp.FileSHA256,
			ThumbnailEncSha256: thumbnailResp.FileEncSHA256,
			JpegThumbnail: jpegBytes,
			MediaKey:      uploaded.MediaKey,
			Mimetype:      proto.String(http.DetectContentType(data)),
			FileEncSha256: uploaded.FileEncSHA256,
			FileSha256:    uploaded.FileSHA256,
			FileLength:    proto.Uint64(uint64(len(data))),
		}}
		resp, err := cli.SendMessage(context.Background(), recipient, msg)
		if err != nil {
			log.Errorf("Error sending video message: %v", err)
		} else {
			log.Infof("Video message sent (server timestamp: %s)", resp.Timestamp)
		}
	
	case "sendaudio":
		if len(args) < 2 {
			log.Errorf("Usage: sendaudio <jid> <audio path>")
			return
		}
		recipient, ok := parseJID(args[0])
		if !ok {
			return
		}
		
		outBuf := new(bytes.Buffer)
		
		command := []string{
			ffmpegScriptPath,
			"-y",
			"-i", args[1],
			"-hide_banner",
			"-nostats",
			"-loglevel", "0",
			"-codec:a", "libopus",
			"-ac", "1",
			"-ar", "48000",
			"-f", "ogg",
			"pipe:1",
		}
		
		cmd := exec.Command("sh", command...)
		cmd.Stdout = outBuf
		
		err := cmd.Run()
		if err != nil {
			log.Errorf("Error while using ffmpeg to fix audio: %s", err)
			log.Errorf("Sending raw and unfixed audio")
			data, err := os.ReadFile(args[1])
			if err != nil {
				log.Errorf("Failed to read %s: %v", args[1], err)
				return
			}
			uploaded := whatsmeow.UploadResponse{}
			if recipient.Server == types.NewsletterServer {
				uploaded, err = cli.UploadNewsletter(context.Background(), data, whatsmeow.MediaAudio)
			} else {
				uploaded, err = cli.Upload(context.Background(), data, whatsmeow.MediaAudio)
			}
			//uploaded, err := cli.Upload(context.Background(), data, whatsmeow.MediaAudio)
			if err != nil {
				log.Errorf("Failed to upload file: %v", err)
				return
			}
			
			msg := &waProto.Message{AudioMessage: &waProto.AudioMessage{
				Url:           proto.String(uploaded.URL),
				DirectPath:    proto.String(uploaded.DirectPath),
				MediaKey:      uploaded.MediaKey,
				Mimetype:      proto.String("audio/ogg; codecs=opus"),
				FileEncSha256: uploaded.FileEncSHA256,
				FileSha256:    uploaded.FileSHA256,
				FileLength:    proto.Uint64(uint64(len(data))),
			}}
			resp, err := cli.SendMessage(context.Background(), recipient, msg)
			if err != nil {
				log.Errorf("Error sending audio message: %v", err)
			} else {
				log.Infof("Audio message sent (server timestamp: %s)", resp.Timestamp)
			}
			return
		}
		
		data := outBuf.Bytes()
		
		err = nil
		uploaded := whatsmeow.UploadResponse{}
		if recipient.Server == types.NewsletterServer {
			uploaded, err = cli.UploadNewsletter(context.Background(), data, whatsmeow.MediaAudio)
		} else {
			uploaded, err = cli.Upload(context.Background(), data, whatsmeow.MediaAudio)
		}
		//uploaded, err := cli.Upload(context.Background(), data, whatsmeow.MediaAudio)
		if err != nil {
			log.Errorf("Failed to upload file: %v", err)
			return
		}
		
		msg := &waProto.Message{AudioMessage: &waProto.AudioMessage{
			Url:           proto.String(uploaded.URL),
			DirectPath:    proto.String(uploaded.DirectPath),
			MediaKey:      uploaded.MediaKey,
			Mimetype:      proto.String("audio/ogg; codecs=opus"),
			FileEncSha256: uploaded.FileEncSHA256,
			FileSha256:    uploaded.FileSHA256,
			FileLength:    proto.Uint64(uint64(len(data))),
		}}
		resp, err := cli.SendMessage(context.Background(), recipient, msg)
		if err != nil {
			log.Errorf("Error sending audio message: %v", err)
		} else {
			log.Infof("Audio message sent (server timestamp: %s)", resp.Timestamp)
		}
	case "sendimg":
		if len(args) < 2 {
			log.Errorf("Usage: sendimg <jid> <image path> [caption]")
			return
		}
		recipient, ok := parseJID(args[0])
		if !ok {
			return
		}
		data, err := os.ReadFile(args[1])
		if err != nil {
			log.Errorf("Failed to read %s: %v", args[1], err)
			return
		}
		
		isCompatible := false
		
		mimeType := mimemagic.MatchMagic(data)
		
		if len(mimeType.Extensions) != 0 {
			compatibleFormats := []string{".jpg", ".jpeg", ".jpe", ".png"}
			joinedFormats := strings.Join(compatibleFormats, "|")
			isCompatible = strings.Contains(strings.Join(mimeType.Extensions, "|"), joinedFormats)
		}
		
		outBuf := new(bytes.Buffer)
		
		command := []string{
			ffmpegScriptPath,
			"-y",
			"-i", args[1],
			"-hide_banner",
			"-nostats",
			"-loglevel", "0",
			"-vframes", "1",
			"-q:v", "0",
			"-f", "mjpeg",
			"pipe:1",
		}
		
		cmd := exec.Command("sh", command...)
		cmd.Stdout = outBuf
		
		err = cmd.Run()
		if err != nil {
			log.Errorf("Error while using ffmpeg to create thumbnail: %s", err)
			log.Infof("Using fallback method to generate thumbnail")
			imageFile, err := os.Open(args[1])
			if err != nil {
				log.Errorf("Error opening image file: %s", err)
				return
			}
			img, _, err := image.Decode(imageFile)
			if err != nil {
				log.Errorf("Error decoding image: %s", err)
				log.Errorf("Sending image without preview thumbnail")
				err := error(nil)
				uploaded := whatsmeow.UploadResponse{}
				if recipient.Server == types.NewsletterServer {
					uploaded, err = cli.UploadNewsletter(context.Background(), data, whatsmeow.MediaImage)
				} else {
					uploaded, err = cli.Upload(context.Background(), data, whatsmeow.MediaImage)
				}
				//uploaded, err := cli.Upload(context.Background(), data, whatsmeow.MediaImage)
				if err != nil {
					log.Errorf("Failed to upload file: %v", err)
					return
				}
			    msg := &waProto.Message{ImageMessage: &waProto.ImageMessage{
				    Caption:       proto.String(strings.Join(args[2:], " ")),
				    Url:           proto.String(uploaded.URL),
				    DirectPath:    proto.String(uploaded.DirectPath),
				    MediaKey:      uploaded.MediaKey,
				    Mimetype:      proto.String(http.DetectContentType(data)),
				    FileEncSha256: uploaded.FileEncSHA256,
				    FileSha256:    uploaded.FileSHA256,
				    FileLength:    proto.Uint64(uint64(len(data))),
			    }}
			    resp, err := cli.SendMessage(context.Background(), recipient, msg)
			    if err != nil {
				    log.Errorf("Error sending image message: %v", err)
			    } else {
				    log.Infof("Image message sent (server timestamp: %s)", resp.Timestamp)
			    }
				return
			}
			imageFile.Close()
			
			thumbnail := resizeImage(img)
			
			buffer := new(bytes.Buffer)
			
			err = jpeg.Encode(buffer, thumbnail, nil)
			if err != nil {
				log.Errorf("Error encoding thumbnail: %s", err)
				return
			}
			
			jpegBytes := buffer.Bytes()
			
			uploaded := whatsmeow.UploadResponse{}
			if recipient.Server == types.NewsletterServer {
				uploaded, err = cli.UploadNewsletter(context.Background(), data, whatsmeow.MediaImage)
			} else {
				uploaded, err = cli.Upload(context.Background(), data, whatsmeow.MediaImage)
			}
			//uploaded, err := cli.Upload(context.Background(), data, whatsmeow.MediaImage)
			if err != nil {
				log.Errorf("Failed to upload file: %v", err)
				return
			}
			thumbnailResp := whatsmeow.UploadResponse{}
			if recipient.Server == types.NewsletterServer {
				thumbnailResp, err = cli.UploadNewsletter(context.Background(), jpegBytes, whatsmeow.MediaImage)
			} else {
				thumbnailResp, err = cli.Upload(context.Background(), jpegBytes, whatsmeow.MediaImage)
			}
			//thumbnailResp, err := cli.Upload(context.Background(), jpegBytes, whatsmeow.MediaImage)
			if err != nil {
				log.Errorf("Failed to upload preview thumbnail file: %v", err)
				return
			}
		    msg := &waProto.Message{ImageMessage: &waProto.ImageMessage{
			    Caption:       proto.String(strings.Join(args[2:], " ")),
			    Url:           proto.String(uploaded.URL),
			    DirectPath:    proto.String(uploaded.DirectPath),
			    ThumbnailDirectPath: &thumbnailResp.DirectPath,
			    ThumbnailSha256: thumbnailResp.FileSHA256,
			    ThumbnailEncSha256: thumbnailResp.FileEncSHA256,
			    JpegThumbnail: jpegBytes,
			    MediaKey:      uploaded.MediaKey,
			    Mimetype:      proto.String(http.DetectContentType(data)),
			    FileEncSha256: uploaded.FileEncSHA256,
			    FileSha256:    uploaded.FileSHA256,
			    FileLength:    proto.Uint64(uint64(len(data))),
		    }}
		    resp, err := cli.SendMessage(context.Background(), recipient, msg)
		    if err != nil {
			    log.Errorf("Error sending image message: %v", err)
		    } else {
			    log.Infof("Image message sent (server timestamp: %s)", resp.Timestamp)
		    }
			
			return
		}
		
		outBytes := outBuf.Bytes()
		img, _, err := image.Decode(outBuf)
		if err != nil {
			log.Errorf("Error decoding image: %s", err)
			return
		}
		
		thumbnail := resizeImage(img)
		
		buffer := new(bytes.Buffer)
		
		err = jpeg.Encode(buffer, thumbnail, nil)
		if err != nil {
			log.Errorf("Error encoding thumbnail: %s", err)
			return
		}
		
		jpegBytes := buffer.Bytes()
		
		uploaded := whatsmeow.UploadResponse{}
		lenData := len(data)
		contentData := data
		if isCompatible {
			err := error(nil)
			if recipient.Server == types.NewsletterServer {
				uploaded, err = cli.UploadNewsletter(context.Background(), data, whatsmeow.MediaImage)
			} else {
				uploaded, err = cli.Upload(context.Background(), data, whatsmeow.MediaImage)
			}
			//uploaded, err = cli.Upload(context.Background(), data, whatsmeow.MediaImage)
			if err != nil {
				log.Errorf("Failed to upload file: %v", err)
				return
			}
		} else {
			lenData = len(outBytes)
			contentData = outBytes
			err := error(nil)
			if recipient.Server == types.NewsletterServer {
				uploaded, err = cli.UploadNewsletter(context.Background(), outBytes, whatsmeow.MediaImage)
			} else {
				uploaded, err = cli.Upload(context.Background(), outBytes, whatsmeow.MediaImage)
			}
			//uploaded, err = cli.Upload(context.Background(), outBytes, whatsmeow.MediaImage)
			if err != nil {
				log.Errorf("Failed to upload file: %v", err)
				return
			}
		}
		err = nil
		thumbnailResp := whatsmeow.UploadResponse{}
		if recipient.Server == types.NewsletterServer {
			thumbnailResp, err = cli.UploadNewsletter(context.Background(), jpegBytes, whatsmeow.MediaImage)
		} else {
			thumbnailResp, err = cli.Upload(context.Background(), jpegBytes, whatsmeow.MediaImage)
		}
		//thumbnailResp, err := cli.Upload(context.Background(), jpegBytes, whatsmeow.MediaImage)
		if err != nil {
			log.Errorf("Failed to upload preview thumbnail file: %v", err)
			return
		}
	    msg := &waProto.Message{ImageMessage: &waProto.ImageMessage{
		    Caption:       proto.String(strings.Join(args[2:], " ")),
		    Url:           proto.String(uploaded.URL),
		    DirectPath:    proto.String(uploaded.DirectPath),
		    ThumbnailDirectPath: &thumbnailResp.DirectPath,
		    ThumbnailSha256: thumbnailResp.FileSHA256,
		    ThumbnailEncSha256: thumbnailResp.FileEncSHA256,
		    JpegThumbnail: jpegBytes,
		    MediaKey:      uploaded.MediaKey,
		    Mimetype:      proto.String(http.DetectContentType(contentData)),
		    FileEncSha256: uploaded.FileEncSHA256,
		    FileSha256:    uploaded.FileSHA256,
		    FileLength:    proto.Uint64(uint64(lenData)),
	    }}
	    resp, err := cli.SendMessage(context.Background(), recipient, msg)
	    if err != nil {
		    log.Errorf("Error sending image message: %v", err)
	    } else {
		    log.Infof("Image message sent (server timestamp: %s)", resp.Timestamp)
	    }
	case "markread":
		if len(args) < 2 {
			log.Errorf("Usage: markread <jid> <message ID 1> [message ID X] (Note: Can add multiple message IDs to mark as read. [] is optional)")
			return
		}
		recipient, ok := parseJID(args[0])
		if !ok {
			return
		}
		
		messageID := make([]string, 0, len(args)-1)
		for _, id := range args[1:] {
		    if id != "" {
		        messageID = append(messageID, id)
		    }
		}
		
		err := cli.MarkRead(messageID, time.Now(), recipient, types.EmptyJID)
		if err != nil {
			log.Errorf("Error sending mark as read: %v", err)
		} else {
			log.Infof("Mark as read sent")
		}
	case "batchmessagegroupmembers":
		if len(args) < 2 {
			log.Errorf("Usage: batchsendgroupmembers <group jid> <text>")
			return
		}
		group, ok := parseJID(args[0])
		if !ok {
			return
		} else if group.Server != types.GroupServer {
			log.Errorf("Input must be a group JID (@%s)", types.GroupServer)
			log.Errorf("Usage: batchsendgroupmembers send <group jid> <text>")
			return
		}
		resp, err := cli.GetGroupInfo(group)
		if err != nil {
			log.Errorf("Failed to get group info: %v", err)
		} else {
			for _, participant := range resp.Participants {
				participant_jid := fmt.Sprintf("%s", participant.JID)
				if participant_jid == default_jid {
					log.Infof("skipped messaging self")
				} else {
					new_args := []string{}
					new_args = append(new_args, participant_jid)
					new_args = append(new_args, args[1:]...)
					handleCmd("send", new_args[0:])
				}
			}
		}
	case "setpushname":
		if len(args) == 0 {
			log.Errorf("Usage: setpushname <name>")
			return
		}
		err := cli.SendAppState(appstate.BuildSettingPushName(strings.Join(args, " ")))
		if err != nil {
			log.Errorf("Error setting push name: %v", err)
		} else {
			log.Infof("Push name updated")
		}
	case "setstatus":
		if len(args) == 0 {
			log.Errorf("Usage: setstatus <message>")
			return
		}
		err := cli.SetStatusMessage(strings.Join(args, " "))
		if err != nil {
			log.Errorf("Error setting status message: %v", err)
		} else {
			log.Infof("Status updated")
		}
	case "archive":
		if len(args) < 2 {
			log.Errorf("Usage: archive <jid> <action>")
			return
		}
		target, ok := parseJID(args[0])
		if !ok {
			return
		}
		action, err := strconv.ParseBool(args[1])
		if err != nil {
			log.Errorf("invalid second argument: %v", err)
			return
		}
		if *isMode != "both" && *isMode != "send" {
			names := []appstate.WAPatchName{appstate.WAPatchName(args[0])}
			new_args := []string{"all"}
			if new_args[0] == "all" {
				names = []appstate.WAPatchName{appstate.WAPatchRegular, appstate.WAPatchRegularHigh, appstate.WAPatchRegularLow, appstate.WAPatchCriticalUnblockLow, appstate.WAPatchCriticalBlock}
			}
			
			resync := len(new_args) > 1 && new_args[1] == "resync"
			for _, name := range names {
				cli.FetchAppState(name, resync, false)
			}
		}
		err = cli.SendAppState(appstate.BuildArchive(target, action, time.Time{}, nil))
		if err != nil {
			log.Errorf("Error changing chat'\''s archive state: %v", err)
		}
	case "mute":
		if len(args) < 2 {
			log.Errorf("Usage: mute <jid> <action> <hours> (default is 8hrs, if 0 then indefinitely)")
			return
		}
		target, ok := parseJID(args[0])
		if !ok {
			return
		}
		action, err := strconv.ParseBool(args[1])
		if err != nil {
			log.Errorf("invalid second argument: %v", err)
			return
		}
		var hours time.Duration
		if len(args) < 3 {
			hours, _ = time.ParseDuration("8h")
		} else {
			t, _ := strconv.ParseInt(args[2], 10, 64)
			if t == 0 {
				hours, _ = time.ParseDuration("318538h")
			} else if t > 0 && t <= 168 {
				hours, _ = time.ParseDuration(fmt.Sprintf("%dh", t))
			} else {
				hours, _ = time.ParseDuration("8h")
			}
		}
		if *isMode != "both" && *isMode != "send" {
			names := []appstate.WAPatchName{appstate.WAPatchName(args[0])}
			new_args := []string{"all"}
			if new_args[0] == "all" {
				names = []appstate.WAPatchName{appstate.WAPatchRegular, appstate.WAPatchRegularHigh, appstate.WAPatchRegularLow, appstate.WAPatchCriticalUnblockLow, appstate.WAPatchCriticalBlock}
			}
			
			resync := len(new_args) > 1 && new_args[1] == "resync"
			for _, name := range names {
				cli.FetchAppState(name, resync, false)
			}
		}
		err = cli.SendAppState(appstate.BuildMute(target, action, hours))
		if err != nil {
			log.Errorf("Error changing chat'\''s mute state: %v", err)
		} else {
			if action {
					log.Infof("Changed mute state for JID: %s, state: %t, duration: %s", target, action, hours)
				} else {
					log.Infof("Changed mute state for JID: %s, state: %t", target, action)
				}
		}
	case "pin":
		if len(args) < 2 {
			log.Errorf("Usage: pin <jid> <action>")
			return
		}
		target, ok := parseJID(args[0])
		if !ok {
			return
		}
		action, err := strconv.ParseBool(args[1])
		if err != nil {
			log.Errorf("invalid second argument: %v", err)
			return
		}
		if *isMode != "both" && *isMode != "send" {
			names := []appstate.WAPatchName{appstate.WAPatchName(args[0])}
			new_args := []string{"all"}
			if new_args[0] == "all" {
				names = []appstate.WAPatchName{appstate.WAPatchRegular, appstate.WAPatchRegularHigh, appstate.WAPatchRegularLow, appstate.WAPatchCriticalUnblockLow, appstate.WAPatchCriticalBlock}
			}
			
			resync := len(new_args) > 1 && new_args[1] == "resync"
			for _, name := range names {
				cli.FetchAppState(name, resync, false)
			}
		}
		err = cli.SendAppState(appstate.BuildPin(target, action))
		if err != nil {
			log.Errorf("Error changing chat'\''s pin state: %v", err)
		}
	case "getblocklist":
		blocklist, err := cli.GetBlocklist()
		if err != nil {
			log.Errorf("Failed to get blocked contacts list: %v", err)
		} else {
			log.Infof("Blocklist: %+v", blocklist)
		}
	case "block":
		if len(args) < 1 {
			log.Errorf("Usage: block <jid>")
			return
		}
		jid, ok := parseJID(args[0])
		if !ok {
			return
		}
		resp, err := cli.UpdateBlocklist(jid, events.BlocklistChangeActionBlock)
		if err != nil {
			log.Errorf("Error updating blocklist: %v", err)
		} else {
			log.Infof("Blocklist updated: %+v", resp)
		}
	case "unblock":
		if len(args) < 1 {
			log.Errorf("Usage: unblock <jid>")
			return
		}
		jid, ok := parseJID(args[0])
		if !ok {
			return
		}
		resp, err := cli.UpdateBlocklist(jid, events.BlocklistChangeActionUnblock)
		if err != nil {
			log.Errorf("Error updating blocklist: %v", err)
		} else {
			log.Infof("Blocklist updated: %+v", resp)
		}
	case "labelchat":
		if len(args) < 3 {
			log.Errorf("Usage: labelchat <jid> <labelID> <action>")
			return
		}
		jid, ok := parseJID(args[0])
		if !ok {
			return
		}
		labelID := args[1]
		action, err := strconv.ParseBool(args[2])
		if err != nil {
			log.Errorf("invalid third argument: %v", err)
			return
		}

		err = cli.SendAppState(appstate.BuildLabelChat(jid, labelID, action))
		if err != nil {
			log.Errorf("Error changing chat'\''s label state: %v", err)
		}
	case "labelmessage":
		if len(args) < 4 {
			log.Errorf("Usage: labelmessage <jid> <labelID> <messageID> <action>")
			return
		}
		jid, ok := parseJID(args[0])
		if !ok {
			return
		}
		labelID := args[1]
		messageID := args[2]
		action, err := strconv.ParseBool(args[3])
		if err != nil {
			log.Errorf("invalid fourth argument: %v", err)
			return
		}

		err = cli.SendAppState(appstate.BuildLabelMessage(jid, labelID, messageID, action))
		if err != nil {
			log.Errorf("Error changing message'\''s label state: %v", err)
		}
	case "editlabel":
		if len(args) < 4 {
			log.Errorf("Usage: editlabel <labelID> <name> <color> <action>")
			return
		}
		labelID := args[0]
		name := args[1]
		color, err := strconv.Atoi(args[2])
		if err != nil {
			log.Errorf("invalid third argument: %v", err)
			return
		}
		action, err := strconv.ParseBool(args[3])
		if err != nil {
			log.Errorf("invalid fourth argument: %v", err)
			return
		}

		err = cli.SendAppState(appstate.BuildLabelEdit(labelID, name, int32(color), action))
		if err != nil {
			log.Errorf("Error editing label: %v", err)
		}
	}
}
	//stop
'

start_line=""
end_line=""
start_line="$(grep -nm 1 -F 'log.Infof("Revocation sent (server timestamp: %s)", resp.Timestamp)' whatsmeow/mdtest/main.go | grep -Eo '^[0-9]+')"
end_line="$(wc -l whatsmeow/mdtest/main.go | grep -Eo "^[0-9]+")"
i="$start_line"

while (( $i < $end_line ))
do
    ((i++))
    if sed -n "${i}p" whatsmeow/mdtest/main.go | grep -q '}'
    then
        sed -i -e "${i}r /dev/stdin" whatsmeow/mdtest/main.go <<< $code_body
        break
    fi
done

code_body='
			//start
			if recipient.Server == types.GroupServer {
				msg.MessageContextInfo = &waProto.MessageContextInfo{MessageSecret: random.Bytes(32)}
			}
			//stop
'

grep -n -E 'cli\.SendMessage\(.*msg\)' whatsmeow/mdtest/main.go | sed 's/:.*//' | sort -Vr | while read -r line; do line="$(($line-1))"; sed -i -e "${line}r /dev/stdin" whatsmeow/mdtest/main.go <<< "$code_body"; done

