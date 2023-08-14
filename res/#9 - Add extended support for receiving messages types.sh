#!/data/data/com.termux/files/usr/bin/bash

step_name="$(basename "$0" | sed -E 's/^#[0-9]+ - //' | sed -E 's/\.sh$//')"
step_number="$(basename "$0" | grep -Eo '^#[0-9]+' | sed -E 's/#//')"
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
		if *isMode == "both" || *isMode == "receive" {
			go func() {
				isSupported := false
				jsonData := "{}"
				path := ""
				newPath := ""
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
					is_from_myself = "1"
				} else {
					is_from_myself = "0"
				}
				is_group := ""
				if evt.Info.MessageSource.IsGroup {
					is_group = "1"
				} else {
					is_group = "0"
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
					
					jsonData, _ = AppendToJSON(jsonData, "type", "message")
					jsonData, _ = AppendToJSON(jsonData, "message", message)
					jsonData, _ = AppendToJSON(jsonData, "message_id", message_id)
				} else if evt.Message.GetExtendedTextMessage() != nil {
					isSupported = true
					extended_message := fmt.Sprintf("%s", evt.Message.ExtendedTextMessage.GetText())
					
					jsonData, _ = AppendToJSON(jsonData, "type", "extended_message")
					jsonData, _ = AppendToJSON(jsonData, "message", extended_message)
					jsonData, _ = AppendToJSON(jsonData, "message_id", message_id)
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
					jsonData, _ = AppendToJSON(jsonData, "question", question)
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
				} else if evt.Message.GetLocationMessage() != nil {
					
					isSupported = true
					jsonData, _ = AppendToJSON(jsonData, "type", "location_message")
					jsonData, _ = AppendToJSON(jsonData, "message_id", message_id)
					locData := evt.Message.GetLocationMessage()
					latitude := fmt.Sprintf("%f", locData.GetDegreesLatitude())
					longitude := fmt.Sprintf("%f", locData.GetDegreesLongitude())
					jsonData, _ = AppendToJSON(jsonData, "latitude", latitude)
					jsonData, _ = AppendToJSON(jsonData, "longitude", longitude)
					locThumbnail := locData.GetJpegThumbnail()
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
						jsonData, _ = AppendToJSON(jsonData, "caption", caption)
					}
					latitude := fmt.Sprintf("%f", locData.GetDegreesLatitude())
					longitude := fmt.Sprintf("%f", locData.GetDegreesLongitude())
					jsonData, _ = AppendToJSON(jsonData, "latitude", latitude)
					jsonData, _ = AppendToJSON(jsonData, "longitude", longitude)
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
				} else if evt.Message.GetContactMessage() != nil {
					
					isSupported = true
					jsonData, _ = AppendToJSON(jsonData, "type", "contact_message")
					jsonData, _ = AppendToJSON(jsonData, "message_id", message_id)
					display_name := fmt.Sprintf("%s", evt.Message.ContactMessage.GetDisplayName())
					vcard := fmt.Sprintf("%s", evt.Message.ContactMessage.GetVcard())
					jsonData, _ = AppendToJSON(jsonData, "display_name", display_name)
					os.MkdirAll(filepath.Join(currentDir, "media", "contact"), os.ModePerm)
					path = filepath.Join(currentDir, "media", "contact", fmt.Sprintf("%s.vcf", evt.Info.ID))
					err := os.WriteFile(tmpPath, []byte(vcard), 0644)
					if err != nil {
						log.Errorf("Failed to save vcard: %v", err)
						return
					}
					log.Infof("Saved vcard in message to %s", path)
					jsonData, _ = AppendToJSON(jsonData, "path", path)
				} else if evt.Message.GetContactsArrayMessage() != nil {
					
					isSupported = true
					jsonData, _ = AppendToJSON(jsonData, "type", "contact_message")
					jsonData, _ = AppendToJSON(jsonData, "message_id", message_id)
					os.MkdirAll(filepath.Join(currentDir, "media", "contact"), os.ModePerm)
					contactData := evt.Message.GetContactsArrayMessage()
					for i, contactInfo  := range contactData.GetContacts() {
						display_name := fmt.Sprintf("%s", contactInfo.GetDisplayName())
						jsonData, _ = AppendToJSON(jsonData, "display_name", display_name)
						vcard := fmt.Sprintf("%s", contactInfo.GetVcard())
						tmpPath := filepath.Join(currentDir, "media", "contact", fmt.Sprintf("%s-%d.vcf", evt.Info.ID, i+1))
						err := os.WriteFile(path, []byte(vcard), 0644)
						if err != nil {
							log.Errorf("Failed to save vcard: %v", err)
						} else {
							log.Infof("Saved vcard in message to %s", tmpPath)
							jsonData, _ = AppendToJSON(jsonData, "path", tmpPath)
							if isSupported {
								log.Infof("%s", jsonData)
								//http
								httpPath := "/message"
								go sendHttpPost(jsonData, httpPath)
							}
							if *autoDelete {
								go func() {
									if tmpPath != "" {
										time.Sleep(30 * time.Second)
										os.Remove(tmpPath)
									}
								}()
							}
						}
					}
					return
				} else if *saveMedia {
					
					if evt.Message.GetImageMessage() != nil {
						isSupported = true
						jsonData, _ = AppendToJSON(jsonData, "type", "image_message")
						jsonData, _ = AppendToJSON(jsonData, "message_id", message_id)
						imgData := evt.Message.GetImageMessage()
						caption := imgData.GetCaption()
						if caption != "" {
							jsonData, _ = AppendToJSON(jsonData, "caption", caption)
						}
						data, err := cli.Download(imgData)
						if err != nil {
							log.Errorf("Failed to download image: %v", err)
							return
						}
						os.MkdirAll(filepath.Join(currentDir, "media", "image"), os.ModePerm)
						path = filepath.Join(currentDir, "media", "image", fmt.Sprintf("%s.tmp", evt.Info.ID))
						err = os.WriteFile(path, data, 0644)
						if err != nil {
							log.Errorf("Failed to save image: %v", err)
							return
						}
						mimeType, err := mimemagic.MatchFilePath(path, -1)
						if len(mimeType.Extensions) == 0 || err != nil {
							log.Errorf("Image message extension unknown, saving as %s", path)
							jsonData, _ = AppendToJSON(jsonData, "path", path)
						} else {
							newPath = filepath.Join(currentDir, "media", "image", fmt.Sprintf("%s%s", evt.Info.ID, mimeType.Extensions[0]))
							os.Rename(path, newPath)
							log.Infof("Saved image in message to %s", newPath)
							jsonData, _ = AppendToJSON(jsonData, "path", newPath)
						}
					} else if evt.Message.GetVideoMessage() != nil {
						isSupported = true
						jsonData, _ = AppendToJSON(jsonData, "type", "video_message")
						jsonData, _ = AppendToJSON(jsonData, "message_id", message_id)
						vidData := evt.Message.GetVideoMessage()
						caption := vidData.GetCaption()
						if caption != "" {
							jsonData, _ = AppendToJSON(jsonData, "caption", caption)
						}
						data, err := cli.Download(vidData)
						if err != nil {
							log.Errorf("Failed to download video: %v", err)
							return
						}
						os.MkdirAll(filepath.Join(currentDir, "media", "video"), os.ModePerm)
						path = filepath.Join(currentDir, "media", "video", fmt.Sprintf("%s.tmp", evt.Info.ID))
						err = os.WriteFile(path, data, 0644)
						if err != nil {
							log.Errorf("Failed to save video: %v", err)
							return
						}
						mimeType, err := mimemagic.MatchFilePath(path, -1)
						if len(mimeType.Extensions) == 0 || err != nil {
							log.Errorf("Video message extension unknown, saving as %s", path)
							jsonData, _ = AppendToJSON(jsonData, "path", path)
						} else {
							newPath = filepath.Join(currentDir, "media", "video", fmt.Sprintf("%s%s", evt.Info.ID, mimeType.Extensions[0]))
							os.Rename(path, newPath)
							log.Infof("Saved video in message to %s", newPath)
							jsonData, _ = AppendToJSON(jsonData, "path", newPath)
						}
					} else if evt.Message.GetDocumentMessage() != nil {
						isSupported = true
						jsonData, _ = AppendToJSON(jsonData, "type", "document_message")
						jsonData, _ = AppendToJSON(jsonData, "message_id", message_id)
						docData := evt.Message.GetDocumentMessage()
						caption := docData.GetCaption()
						if caption != "" {
							jsonData, _ = AppendToJSON(jsonData, "caption", caption)
						}
						file_name := docData.GetFileName()
						if file_name != "" {
							jsonData, _ = AppendToJSON(jsonData, "file_name", file_name)
						}
						data, err := cli.Download(docData)
						if err != nil {
							log.Errorf("Failed to download document: %v", err)
							return
						}
						os.MkdirAll(filepath.Join(currentDir, "media", "document"), os.ModePerm)
						path = filepath.Join(currentDir, "media", "document", fmt.Sprintf("%s.tmp", evt.Info.ID))
						err = os.WriteFile(path, data, 0644)
						if err != nil {
							log.Errorf("Failed to save document: %v", err)
							return
						}
						mimeType, err := mimemagic.MatchFilePath(path, -1)
						if len(mimeType.Extensions) == 0 || err != nil {
							log.Errorf("Document message extension unknown, saving as %s", path)
							jsonData, _ = AppendToJSON(jsonData, "path", path)
						} else {
							newPath = filepath.Join(currentDir, "media", "document", fmt.Sprintf("%s%s", evt.Info.ID, mimeType.Extensions[0]))
							os.Rename(path, newPath)
							log.Infof("Saved document in message to %s", newPath)
							jsonData, _ = AppendToJSON(jsonData, "path", newPath)
						}
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
						os.MkdirAll(filepath.Join(currentDir, "media", "audio"), os.ModePerm)
						path = filepath.Join(currentDir, "media", "audio", fmt.Sprintf("%s.tmp", evt.Info.ID))
						err = os.WriteFile(path, data, 0644)
						if err != nil {
							log.Errorf("Failed to save audio: %v", err)
							return
						}
						mimeType, err := mimemagic.MatchFilePath(path, -1)
						if len(mimeType.Extensions) == 0 || err != nil {
							log.Errorf("Audio message extension unknown, saving as %s", path)
							jsonData, _ = AppendToJSON(jsonData, "path", path)
						} else {
							if mimeType.Extensions[0] == ".ogg" || mimeType.Extensions[0] == ".oga" {
								newPath = filepath.Join(currentDir, "media", "audio", fmt.Sprintf("%s.ogg", evt.Info.ID))
								os.Rename(path, newPath)
								log.Infof("Saved audio in message to %s", newPath)
								jsonData, _ = AppendToJSON(jsonData, "path", newPath)
							} else {
								newPath = filepath.Join(currentDir, "media", "audio", fmt.Sprintf("%s%s", evt.Info.ID, mimeType.Extensions[0]))
								os.Rename(path, newPath)
								log.Infof("Saved audio in message to %s", newPath)
								jsonData, _ = AppendToJSON(jsonData, "path", newPath)
							}
						}
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
						if path != "" || newPath != "" {
							time.Sleep(30 * time.Second)
							os.Remove(path)
							os.Remove(newPath)
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
			}()
		}
		//stop
'

sed -i -e "$(grep -nm 1 -F 'log.Infof("Received message %s from %s (%s): %+v", evt.Info.ID, evt.Info.SourceString(), strings.Join(metaParts, ", "), evt.Message)' whatsmeow/mdtest/main.go | sed 's/:.*//')r /dev/stdin" whatsmeow/mdtest/main.go <<< $code_body
