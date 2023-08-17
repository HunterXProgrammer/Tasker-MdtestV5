# Description
Send WhatsApp Text/Images/Videos/PDF/Documents/Voice Messages automatically using Tasker.

Previous post intro:-

>Recently I've been getting a lot of inquiries on how to send images, videos or documents in WhatsApp using Tasker. Possibly with the screen off, phone locked, without unlocking, etc. Had some time to make this so here it is.

# Details
Contains assets that are used for running Mdtest V5 directly in Tasker, without needing Termux.

Made for Project Mdtest V5.

# List Of Supported Features
- Send Text Messages
- Send Images
- Send Videos
- Send Audio
- Send PDF/Documents
- Send Link Previews (New!)
- Send Poll messages
- Mark as read
- Revoke messages
- Download Media Messages (New!)  
  Now includes downloading media like:-
  - Images, videos, audio, documents, contacts, status, location previews
- Mute/Unmute chats (New!)
- Pin/Unpin chats (New!)
- Archive/Unarchive chats (New!)
- Multi-Number/User support (New!)
  - Previously Mdtest could support only one WhatsApp number, but now you can have as many as you want
- Receive details of incoming messages as Tasker variables. Can use this for automated replies (check **[VARIABLES]()**)  
  Current list of message types that are supported and can be received as Tasker variables:-
  - Text, forwarded text, image, video, audio, document, poll, list, button, status, location(co-ordinates), contact, etc.
- Added support to link WhatsApp using phone number pairing method

### Changes in Mdtest V5 Compared To Previous V4
- Now can link WhatsApp using phone number pairing method.  
  Previous(V4) method of scanning QR code was tiresome and needed a spare device.  
  Now with the new pairing method(V5) everything is done from the main device in a few seconds.
- Better support for sending images/videos/audio.  
  Previously(V4) needed to send an image thumbnail seperately along with the main media file.  
  Now no longer necessary, Mdtest(V5) handles it.
- Added support for receiving media messages and downloading the media file.  
  Includes downloading images/videos/audio/documents/contacts/status/location previews.  
  The media files are stored in `~/whatsmeow5/mdtest/media`.  
  To enable downloading media pass the `--save-media` flag when starting `mdtest`.
- Added support to send link preview messages.  
  Only for websites that support the **[Open Graph](https://ogp.me/)** protocol.  
  Eg:- `https://github.com/HunterXProgrammer/Tasker-MdtestV5`

# Disclaimer
You are responsible for what you do with this.

# Instructions
### For Tasker Users
Check this Tasker Reddit **[post]()** for more info and importable Taskernet links.

### For CLI Users
**NOTE:-**
>This section is helpful for those who want to make shell scripts to use `mdtest` to send messages. Not recommended for Tasker beginners since there are ready made Taskernet links in the Tasker Reddit Post that you can import.

#### CLI In Tasker
Added preliminary CLI support to run `mdtest` from within Tasker itself using action [Run Shell].

1\) Set it up as described in this Tasker Reddit **[post]()**.

This will prepare Tasker to enable CLI support natively.

Your [Run Shell] action to use `mdtest` will look like this -

    #!/system/bin/sh
    mdtest_dir="/data/data/net.dinglisch.android.taskerm/files/whatsmeow5/mdtest"
    cd $mdtest_dir.7774
    sh $mdtest_dir/mdtest FLAGS COMMAND PARAMETERS

Check **[Commands And Parameters](https://github.com/HunterXProgrammer/Tasker-MdtestV5#commands-and-parameters)** for more info about the available CLI commands.

#### CLI In Termux
CLI Setup:-

1\) Install and open **[Termux](https://f-droid.org/en/packages/com.termux/)** in your device.

2\) Grab the pre-compiled  binary from **[releases](https://github.com/HunterXProgrammer/Tasker-MdtestV5/releases/tag/MdtestV5-Assets)** or use the build script to compile it yourself in Termux.

**Eg:-** Depending on your device architecture(use `uname -m` to find out), you can download for `arm`,`arm64`(aarch64),`x86` and `x86_64` like this -

    arch=arm64 && curl -s -L -o "mdtest-${arch}.zip" "https://github.com/HunterXProgrammer/Tasker-MdtestV5/releases/tag/MdtestV5-Assets/mdtest-${arch}.zip" && mkdir -p ~/whatsmeow5/mdtest && unzip -o -d ~/whatsmeow5/mdtest mdtest-${arch}.zip && chmod -R 744 ~/whatsmeow5/mdtest/mdtest

OR

You can build and compile it by yourself in Termux -

    git clone https://github.com/HunterXProgrammer/Tasker-MdtestV5
    cd Tasker-MdtestV5
    bash build_whatsmeow5.sh
    mv whatsmeow5 ~/
    
3\) After that link with WhatsApp like this -

>Now to connect it to WhatsApp -
>
>Type -
>
>`cd ~/whatsmeow5/mdtest; ./mdtest pair-phone 91987654321`
>
>(Here "91" is the country code and "987654321" is the number. Adjust as needed)
>
>This will generate the linking code.
>
>You can copy the linking code and paste it in WhatsApp via notification
>
>or by open WhatsApp -> ⋮ (menu) -> Linked Devices -> Link with phone number
>
>Wait about 15s for pairing to complete. All done.

This finishes the CLI setup.

Your script will look like this -

    #!/data/data/com.termux/files/usr/bin/bash
    cd ~/whatsmeow5/mdtest
    ./mdtest FLAGS COMMAND PARAMETERS

### Commands And Parameters

The **FLAGS** are -

    --save-media
          Download And Save Media.
          This flag also enables receiving media message types
          such as:- images, videos, audio, documents, contacts,
          status, location previews.
          Note:- Will only be effective if "--mode" is "both"
    
    --mode <value>
          Select mode: none, both or send
          (default option: none)
          both -> Mdtest will receive mesages and as well as send messages
          send -> Mdtest will only send messages, not receive.
    
    --port <value>
          Port can be anything from 1024 ~ 65535
          Mdtest accepts requests on this port.
          It must not be 9990
          (default option: 7774)
          Note:-  To be used in conjuction with "--mode"
          Will only accept requests if "--mode" is "both" or "send"
    
    --auto-delete-media
          Delete Downloaded Media After 30s

The **COMMAND** and **PARAMETERS** are:-

    send <jid> <text>
    sendimg <jid> <image path> [caption]
    sendvid <jid> <video path> [caption]
    sendaudio <jid> <audio path>
    senddoc <jid> <document path> <title> [mime-type]
    sendpoll <jid> <max answers> <question> -- <option 1> / <option 2> / ...
    sendlink <jid> <url/link> [text]
    markread <jid> <message ID No.1> [message ID No.X] (Note: Can add multiple message IDs to mark as read. [] is optional)
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
    getgroup <jid>
    subgroups <jid>
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

# Credits
**[whatsmeow](https://github.com/tulir/whatsmeow) -** Go library `mdtest` is based on.

**[Termux](https://github.com/termux/termux-app) -** The best Android terminal. Allows compiling `mdtest` natively without needing PC or cross-toolchains. `ffmpeg` binaries used from here.

**[Comment](https://www.reddit.com/r/tasker/comments/k0r7h9/comment/gdn5ovn/) by [OwlIsBack](https://www.reddit.com/u/OwlIsBack) -** Java functions used in Tasker to get per-line buffer of shell command.
