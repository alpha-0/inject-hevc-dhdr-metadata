## Inject dynamic hdr metadata of hevc video for macOS

This script will extract dolby vision (dv) or hdr10plus metadata from a hevc .mkv/.mp4 video,<BR/>
copy the content of another hdr10 compatible hevc .mkv/.mp4 video with same length and same resolution,<BR/>
and then output those content to a new .mkv video with the dv/hdr10plus metadata injected.<BR/>
<BR/>
The purpose of this script is to fix the missing/incorrect dv/hdr10plus metadata on some
re-encoded videos especially those encoded by ffmpeg.<BR/>
Some ffmpeg seems to encode a dv hdr video to a new video having the same dv profile with dv metadata.<BR/>
However, that new video has no dv metadata in fact (its dv metadata is 0 byte)(tested on 2024-07-19).<BR/>
Therefore, additional work is needed to inject the dv metadata to that new video.<BR/>
And this script is mainly for this purpose.
<BR/><BR/>

### How to Use :
Run the command script directly.<BR/>
It will request your input for both the path of video with dv/hdr10plus metadata and
the path of source video which its content will be copied.<BR/>
Then it will request your input for the path of output (work) folder.<BR/>
After that, the script will run and a new copied video will be
injected with dv metadata at the end.<BR/>
<BR/>
If you are using terminal, you can run the command script with arguments as follows.<BR/>
<BR/>
##### Argument1: full path of source video 1 (.mkv/.mp4). Its dv/hdr10plus metadata would be extracted [Optional]
##### Argument2: full path of source video 2 (.mkv/.mp4). Its video and audio would be copied [Optional]
##### Argument3: full path of output (work) folder [Optional]
<BR/><BR/>

### Download :
```
cd ~/Desktop && git clone https://github.com/alpha-0/inject-hevc-hdr-metadata.git && \
chmod 755 ~/Desktop/inject-hevc-dv-metadata/inject-hevc-hdr-metadata.command
```
<BR/>

### Setup and Run :
Edit the file "inject-hevc-hdr-metadata.command" by any text editor such as "TextEdit.app".

Find the "Settings" section and edit some values if needed.

Find the "Settings of Required Tools" section and edit those path of tools.

Make sure the required tools are installed in the corresponding path.

Save the file.

And then run the file directly.
<BR/><BR/>

### Required Tools :
ffmpeg (exec) : multimedia framework. The latest build is recommended ( https://www.ffmpeg.org/download.html )<BR/>
( To build ffmpeg static binary for intel mac, you may interest on this repository:<BR/>
 https://github.com/alpha-0/ffmpeg-static-OSX-with-hdr10plus )

dovi_tool (exec) : CLI tool for working with Dolby Vision ( https://github.com/quietvoid/dovi_tool )

hdr10plus_tool (exec) : CLI utility to work with HDR10+ in HEVC files ( https://github.com/quietvoid/hdr10plus_tool )

MKVToolNix (app) : a set of tools to create, alter and inspect mkv file ( https://mkvtoolnix.download/downloads.html )
<BR/><BR/>

### To Report Bug :
Please Report to
https://github.com/alpha-0/inject-hevc-hdr-metadata/issues
<BR/><BR/>
