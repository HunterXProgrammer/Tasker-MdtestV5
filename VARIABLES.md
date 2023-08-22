# Description
This Section is recommended for advanced Tasker users.

It contains a detailed list of variables that is populated when a WhatsApp message of the corresponding **TYPE** is received

Based on these variables, you can setup your own Tasks that would analyze the contents of the received messages and send back automated replies.

# List Of Tasker Variables
These variables are populated whenever a WhatApp message of the corresponding **TYPE** is received.

To enable receiving WhatsApp messages as Tasker variables:-

1. Run Task **"Mdtest - Start (V5)"** from the **"Receive Messages [MdtestV5]"** Project in **`%mode` = `both`**

2. Done. Now whenever you receive a WhatsApp message it will run the Task **"This Task Runs When Message Received (V5)"** with all the variables directly usable as per the received message **TYPE**.

**Note:-** Added support for receiving media messages and downloading the media file. 
  - Includes downloading images/videos/audio/documents/status/contacts/links/location previews.
    - To enable downloading media in **Tasker** set variable **`%save_media` = `true`**
      The media files are stored in **`/data/data/net.dinglisch.android.taskerm/files/whatsmeow5/mdtest.7774/media`** **(where `7774` = `%port`)**
    - To enable downloading media in **Terminal(Termux)** pass the **`--save-media`** flag when starting `mdtest`.  
      The media files are stored in **`~/whatsmeow5/mdtest/media`**

### \# Generally Available For All Message Types:-

- **`%type`**  
  It indicates the type of message received.  
  Can be one of:-
  - **`text_message`**
  - **`image_message`**
  - **`video_message`**
  - **`audio_message`**
  - **`document_message`**
  - **`status_message`**
  - **`contact_message`**
  - **`link_message`**
  - **`location_message`**
  - **`poll_response_message`**
  - **`button_response_message`**
  - **`list_response_message`**

- **`%port`**  
  Think of it as a unique identifier.  
  It is used for distinction when you use multiple numbers.

- **`%sender_name`**  
  Name of the sender.  
  Will only be set if the sender is saved in contacts.

- **`%sender_pushname`**  
  Push Name of the sender.

- **`%sender_number`**  
  Phone Number of the sender.  
  Country code followed by the number.  
  Eg:- If country code is "91", then -> 919876543210

- **`%sender_jid`**  
  The JID of the sender.  
  Country code followed by the number and "@s.whatsapp.net" at the end.  
  Eg:- If country code is "91", then -> 919876543210@s.whatsapp.net

- **`%receiver_number`**  
  Phone Number of the receiver.  
  Country code followed by the number.  
  Eg:- If country code is "91", then -> 919876543210

- **`%receiver_jid`**  
  The JID of the receiver.  
  Country code followed by the number and "@s.whatsapp.net" at the end.  
  Eg:- If country code is "91", then -> 919876543210@s.whatsapp.net

- **`%is_from_myself`**  
  If message was sent by yourself.  
  Value is `true` or `false`.

- **`%is_group`**  
  If message was sent in group.  
  Value is `true` or `false`.

- **`%group_name`**  
  Name of the Group.  
  Will only be set if message was sent to group.

- **`%group_number`**  
  Number of the Group.  
  Will only be set if message was sent to group.  
  Eg:- 919876543210-1234567890

- **`%group_jid`**  
  The JID of the group.  
  Will only be set if message was sent to group.  
  Group number followed by "@g.us" at the end.  
  Eg:- 919876543210-1234567890@g.us

- **`%timestamp`**  
  Time stamp of the message.  
  Time is in epoch seconds UTC.

- **`%message_id`**  
  Message ID of the received message.  
  Used in advanced Task like Message Revoke, etc,  
  to identify which message to revoke or mark as read.

#### \# Variables specific to:-  
**\-> `%type` = `text_message`**

- **`%message`**  
  The text in the message.

#### \# Variables specific to:-  
**\-> `%type` = `image_message`**

- **`%message`**  
  The caption in the image message.  

- **`%path`**  
  The path to the downloaded image file.

#### \# Variables specific to:-  
**\-> `%type` = `video_message`**

- **`%message`**  
  The caption in the video message.  

- **`%path`**  
  The path to the downloaded video file.

#### \# Variables specific to:-  
**\-> `%type` = `audio_message`**

- **`%path`**  
  The path to the downloaded audio file.

#### \# Variables specific to:-  
**\-> `%type` = `document_message`**

- **`%message`**  
  The caption in the document message.  

- **`%path`**  
  The path to the downloaded document file.

- **`%document_file_name`**  
  The file name of the document file.

#### \# Variables specific to:-  
**\-> `%type` = `status_message`**

- **`%message`**  
  The caption in the status message.  
  It is similar to `%message` but for caption.

- **`%path`**  
  The path to the downloaded status media file.

#### \# Variables specific to:-  
**\-> `%type` = `contact_message`**

- **`%contact_display_name`**  
  The display name of the shared contact.

- **`%path`**  
  The path to the downloaded contact **`.vcf`** file.

#### \# Variables specific to:-  
**\-> `%type` = `link_message`**

- **`%message`**  
  The text in the message.

- **`%link_title`**  
  The title of the link message.

- **`%link_description`**  
  The description of the link message.

- **`%link_canonical_url`**  
  The canonical url of the link message.

- **`%link_matched_text`**  
  The matched text of the link message.

- **`%path`**  
  The path to the downloaded link message preview image file.

#### \# Variables specific to:-  
**\-> `%type` = `location_message`**

- **`%message`**  
  The caption in the location message.  

- **`%location_latitude`**  
  The latitude co-ordinate in the location message.

- **`%location_longitude`**  
  The longitude co-ordinate in the location message.

- **`%path`**  
  The path to the downloaded location message preview image file.

#### \# Variables specific to:-  
**\-> `%type` = `poll_response_message`**

- **`%poll_question`**  
  The question text in the poll message.  
  Will only be set if the poll response message was received when Mdtest was running.

- **`%poll_selected_options()`**  
  The array that contains the list of selected options.  
  Will only be set if the poll response message was received when Mdtest was running.


#### \# Variables specific to:-  
**\-> `%type` = `button_response_message`**

- **`%button_title`**  
  The title of the button message.

- **`%button_body`**  
  The body of the button message.

- **`%button_footer`**  
  The footer of the button message.

- **`%button_selected_button`**  
  The text of the selected button.

- **`%origin_message_id`**  
  The message id from which the button response message originated from.  
  (**Note:-** It is seperate from `%message_id`)

#### \# Variables specific to:-  
**\-> `%type` = `list_response_message`**

- **`%list_title`**  
  The title of the list message.

- **`%list_body`**  
  The body of the list message.

- **`%list_footer`**  
  The footer of the list message.

- **`%list_header`**  
  The header of the list message.

- **`%list_button_text`**  
  The text of the button of the list message.

- **`%list_selected_title`**  
  The text of the selected title.

- **`%list_selected_description`**  
  The text of the selected description.

- **`%origin_message_id`**  
  The message id from which the button response message originated from.  
  (**Note:-** It is seperate from `%message_id`)
  
