# Description
Send WhatsApp Text/Images/Videos/PDF/Documents/Voice/Poll Messages, plus many more types, automatically using Tasker.

Also supports sending WhatsApp messages from the Terminal(Termux).

Previous post intro:-

>Recently I've been getting a lot of inquiries on how to send images, videos or documents in WhatsApp using Tasker.
>
>Possibly with the screen off, phone locked, without unlocking, etc.

# Details
Contains assets that are used for running Mdtest V5 directly in Tasker.

Also supports sending WhatsApp messages from the Terminal(Termux).

Made for Project Mdtest V5.

# List Of Supported Features
- Send Text Messages
- Send Images
- Send Videos
- Send Audio
- Send PDF/Documents
- Send Link Previews (New!)
- Send List messages (New!)
  - Experimental support for sending list messages.  
    WhatsApp business account not supported, only normal WhatsApp account.  
    More about it here [#372](https://github.com/tulir/whatsmeow/issues/372).
- Send Poll messages
- Mark as read
- Revoke messages
- Download Media Messages (New!)  
  Now includes downloading media like:-
  - Images
  - Videos
  - Audio
  - Documents
  - Status
  - Contacts
  - Link previews
  - Location previews
- Mute/Unmute chats (New!)
- Pin/Unpin chats (New!)
- Archive/Unarchive chats (New!)
- Multi-Number/User support (New!)
  - Previously Mdtest could support only one WhatsApp number, but now you can have as many as you want
- Receive details of incoming messages as Tasker variables. Can use this for automated replies.  
  **-> Be sure to check [VARIABLE.md](https://github.com/HunterXProgrammer/Tasker-MdtestV5/blob/main/VARIABLES.md) for all the available variables.**  
  Current list of message types that are supported and can be received as Tasker variables:-
  - **Text message**
    - text body
  - **Image message**
    - caption message
    - image file
  - **Video message**
    - caption message
    - video file
  - **Audio message**
    - audio file
  - **Document**
    - caption message
    - document name
    - document file
  - **Status message**
    - caption message
    - status media file
  - **Contact message**
    - contact display name
    - contact `.vcf` file
  - **Link message**
    - text body
    - link title
    - link description
    - link url
    - image preview file
  - **Location message**
    - latitude
    - longitude
    - image preview file
  - **Poll response message**
    - poll question
    - poll selected options
  - **Button response message**
    - button title
    - button body
    - button footer
    - selected button
  - **List response message**
    - list title
    - list body
    - list footer
    - list header
    - list button text
    - selected title
    - selected description
- Added support to link WhatsApp using phone number pairing method

### Changes in Mdtest V5 Compared To Previous V4
- Now can link WhatsApp using phone number pairing method.  
  **(Old V4)** Previous method of scanning QR code was tiresome and needed a spare device.  
  **(New V5)** Now with the new pairing method everything is done from the main device in a few seconds.
- Better support for sending images/videos/audio.  
  **(Old V4)** Previously needed to send an image thumbnail seperately along with the main media file.  
  **(New V5)** Now no longer necessary, Mdtest(V5) handles it.
- Added support for receiving media messages and downloading the media file. 
  - Includes downloading images/videos/audio/documents/status/contacts/links/location previews.
    - To enable receiving media messages and downloading media in **Tasker** set variable **`%save_media` = `true`**  
      The media files are stored in **`/data/data/net.dinglisch.android.taskerm/files/whatsmeow5/mdtest.7774/media`** **(where `7774` = `%port`)**
    - To enable receiving media messages and in **Terminal(Termux)** pass the **`--save-media`** flag when starting `mdtest`.  
      The media files are stored in **`~/whatsmeow5/mdtest/media`**
- Added support to send link preview messages.  
  Only for websites that support the **[Open Graph](https://ogp.me/)** protocol.  
  **Eg:- `https://github.com/HunterXProgrammer/Tasker-MdtestV5`**

# Disclaimer
You are responsible for what you do with this.

# Instructions
### For Tasker Users
Check the Tasker Reddit **[post](https://www.reddit.com/r/tasker/comments/15ydqa1/project_share_sendreceive_whatsapp_message/)** for more info and importable Taskernet links.

### For CLI Users
**NOTE:-**
>This section is helpful for those who want to make shell scripts to use `mdtest` to send messages
>
> Not recommended for Tasker beginners since there are ready made Taskernet links in the Tasker Reddit Post that you can import.

#### CLI In Tasker
Added preliminary CLI support to run `mdtest` from within Tasker itself using action [Run Shell].

1\) Set it up as described in this Tasker Reddit **[post](https://www.reddit.com/r/tasker/comments/15ydqa1/project_share_sendreceive_whatsapp_message/)**.

This will prepare Tasker to enable CLI support natively.

Your [Run Shell] action to use `mdtest` will look like this -

    #!/system/bin/sh
    mdtest_dir="/data/data/net.dinglisch.android.taskerm/files/whatsmeow5/mdtest"
    cd $mdtest_dir/../mdtest.7774
    sh $mdtest_dir/mdtest COMMAND PARAMETERS

#### CLI In Termux
CLI Setup:-

1\) Install and open **[Termux](https://f-droid.org/en/packages/com.termux/)** in your device.

2\) Grab the pre-compiled  binary from **[releases](https://github.com/HunterXProgrammer/Tasker-MdtestV5/releases/tag/MdtestV5-Assets)** or use the build script to compile it yourself in Termux.

**Eg:-** Depending on your device architecture(use `uname -m` to find out), you can download for `arm`,`arm64`(aarch64),`x86` and `x86_64` like this -

    arch=arm64 && curl -L -o "mdtest-${arch}.zip" "https://github.com/HunterXProgrammer/Tasker-MdtestV5/releases/download/MdtestV5-Assets/mdtest-${arch}.zip" && mkdir -p ~/whatsmeow5/mdtest && unzip -o -d ~/whatsmeow5/mdtest mdtest-${arch}.zip && chmod -R 744 ~/whatsmeow5/mdtest/mdtest

OR

You can build and compile it by yourself in Termux -

    rm -rf Tasker-MdtestV5 &>/dev/null
    git clone https://github.com/HunterXProgrammer/Tasker-MdtestV5
    cd Tasker-MdtestV5
    bash build_whatsmeow5.sh
    cd ..
    
3\) After that link with WhatsApp like this -

>Now to connect it to WhatsApp -
>
>Type -
>
>`cd ~/whatsmeow5/mdtest; ./mdtest pair-phone 919876543210`
>
>(Here "91" is the country code and "9876543210" is the number. Adjust as needed)
>
>This will generate the linking code.
>
>You can copy the linking code and paste it in WhatsApp via notification
>
>or by open WhatsApp -> ⋮ (menu) -> Linked Devices -> Link with phone number
>
>Wait about 20s for pairing to complete. All done.

This finishes the CLI setup.

Your script will look like this -

    #!/data/data/com.termux/files/usr/bin/bash
    cd ~/whatsmeow5/mdtest
    ./mdtest FLAGS COMMAND PARAMETERS

### Commands And Parameters

The **FLAGS** are -

    --mode <value>
          Select mode: none, both or send
          (default option: none)
          - both -> Mdtest will receive mesages and as well as send messages
          - send -> Mdtest will only send messages, not receive.
    
    --save-media
          Download And Save Media.
          - This flag also enables receiving media message types
            such as:- images, videos, audio, documents, contacts,
            status, location previews.
          - Media saved to ~/whatsmeow5/mdtest/media
          - Note:- To be used in conjuction with "--mode <value>"
                   Will only be effective if "<value>" is "both"
    
    --port <value>
          Port can be anything from 1024 ~ 65535
          It must not be 9990
          (default option: 7774)
          - Mdtest accepts requests on this port.
          - Note:-  To be used in conjuction with "--mode <value>"
                    Will only accept requests if "<value>" is "both" or "send"
    
    --auto-delete-media
          Delete Downloaded Media After 30s
          - Useful for auto-deleting rubbish media that probably won't
            ever be used.
          - The idea is that if the user doesn't use the
            downloaded media after 30s, save space by deleting
            what is most likely redundant files.
          - Note:- To be used in conjunction with "--save-media"

The **COMMAND** and **PARAMETERS** are:-

    send <jid> <text>
    sendimg <jid> <image path> [caption]
    sendvid <jid> <video path> [caption]
    sendaudio <jid> <audio path>
    senddoc <jid> <document path> <document file name> [caption] [mime-type]
    sendpoll <jid> <max answers> <question> -- <option 1> / <option 2> / ...
    sendlink <jid> <url/link> [text]
    sendlist <jid> <title> <text> <footer> <button text> <sub title> -- <heading 1> <description 1> / [heading 2] [description2] / ...
    markread <jid> <message ID>
    revoke <jid> <message ID>
    listusers <jid>
    listgroups <group jid>
    batchsendgroupmembers <group jid> <text>
    archive <jid> <true/false>
    mute <jid> <true/false> <hours> (default is 8hrs, if 0 then indefinitely)
    pin <jid> <true/false>
    pair-phone <number>
    appstate <types...>
    request-appstate-key <ids...>
    unavailable-request <chat JID> <sender JID> <message ID>
    checkuser <phone numbers...>
    subscribepresence <jid>
    presence <available/unavailable>
    chatpresence <jid> <composing/paused> [audio]
    getuser <jids...>
    getavatar <jid> [existing ID] [--preview] [--community]
    getgroup <group jid>
    subgroups <group jid>
    communityparticipants <jid>
    getinvitelink <jid> [--reset]
    queryinvitelink <link>
    querybusinesslink <link>
    joininvitelink <link>
    setdisappeartimer <jid> <days>
    multisend <jids...> -- <text>
    react <jid> <message ID> <reaction>
    setstatus <message>
    reconnect
    logout
    checkupdate
    privacysettings
    mediaconn
    getstatusprivacy

The **"<>"** means required, the **"[ ]"** means optional.

#### Note About JID
For single contacts, JID is usually the country-code followed by the phone-number and appended with "@s.whatsapp.net".  
**Eg:-** Say country-code is "91", then JID will be ->  
919876543210@s.whatsapp.net

For group contacts, JID is usually the group phone-number appended with "@g.us".  
**Eg:-** 1234567890987654321@g.us

# Credits
**[whatsmeow](https://github.com/tulir/whatsmeow) -** Go library `mdtest` is based on.

**[Termux](https://github.com/termux/termux-app) -** The best Android terminal. Allows compiling `mdtest` natively without needing PC or cross-toolchains. `ffmpeg` binaries used from here.

**[Comment](https://www.reddit.com/r/tasker/comments/k0r7h9/comment/gdn5ovn/) by [OwlIsBack](https://www.reddit.com/u/OwlIsBack) -** Java functions used in Tasker to get per-line buffer of shell command.
