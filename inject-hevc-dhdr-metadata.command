#!/bin/sh
# Inject dynamic hdr metadata of hevc video for macOS
# This script will extract dolby vision (dv) or hdr10plus metadata from a hevc .mkv/.mp4 video,
# copy the content of another hdr10 compatible hevc .mkv/.mp4 video with same length and same resolution,
# and then output those content to a new .mkv video with the dv/hdr10plus metadata injected.
#
# The purpose of this script is to fix the missing/incorrect dv/hdr10plus metadata on some
# re-encoded videos especially those encoded by ffmpeg.
# Some ffmpeg seems to encode a dv hdr video to a new video having the same dv profile with dv metadata.
# However, that new video has no dv metadata in fact (its dv metadata is 0 byte)(tested on 2024-07-19).
# Therefore, additional work is needed to inject the dv metadata to that new video.
# And this script is mainly for this purpose.
#
# How to Use :
# Run the command script directly.
# It will request your input for both the path of video with dv/hdr10plus metadata and
# the path of source video which its content will be copied.
# Then it will request your input for the path of output (work) folder.
# After that, the script will run and a new copied video will be
# injected with dv/hdr10plus metadata at the end.
#
# If you are using terminal, you can run the command script with arguments as follows.
#
# Argument1: full path of source video 1 (.mkv/.mp4). Its dv/hdr10plus metadata would be extracted [Optional]
# Argument2: full path of source video 2 (.mkv/.mp4). Its video and audio would be copied [Optional]
# Argument3: full path of output (work) folder [Optional]


## Settings
# Set the file dv suffix for the target video (CANNOT BE EMPTY)
OUTPUT_DV_SUFFIX=_dv-injected

# Set the file hdr10plus suffix for the target video (CANNOT BE EMPTY)
OUTPUT_HDR10PLUS_SUFFIX=_hdr10plus-injected

# Set the output(work) folder. Empty means using the same folder as source video 2.
OUTPUT_FOLDER=

# Enable replacing dv metadata even it exists in source video 2 (Default: FALSE)
REPLACE_DV_METADATA=FALSE

# Enable replacing hdr10plus metadata even it exists in source video 2 (Default: FALSE)
REPLACE_HDR10PLUS_METADATA=FALSE

# Enable cleaning up temporary files after creating the target video (Enable: TRUE)
CLEAN_UP_ON_SUCCESS=TRUE

# Enable cleaning up temporary files after error occurs (Enable: TRUE)
CLEAN_UP_ON_ERROR=TRUE


## Settings of Required Tools (+ MKVToolNix app installed in Applications folder)
# Set full path of ffmpeg command
FFMPEG_BIN="/Users/Shared/video_tools/ffmpeg"

# Set full path of ffprobe command (NOT NEEDED IN THIS VERSION)
#FFPROBE_BIN="/Users/Shared/video_tools/ffprobe"

# Set full path of hdr10plus_tool command
HDR10PLUS_TOOL_BIN="/Users/Shared/video_tools/hdr10plus_tool"

# Set full path of dovi_tool command
DOVI_TOOL_BIN="/Users/Shared/video_tools/dovi_tool"

# Set full path of mp4muxer command (NOT NEEDED IN THIS VERSION)
#MP4MUXER_BIN="/Users/Shared/video_tools/mp4muxer"

# Set full path of your Applications folder
APP_DIR="/Applications/"


## Check the required tools first

# Check MKVToolNix installed path
tput bold ; echo ; echo '♻️  ' 'Checking the required tools' ; tput sgr0
echo
MKVTOOLNIX_BIN_PATH=""
APP_DIR=${APP_DIR%/}
for mkvdir in $(find ${APP_DIR}/MKVToolNix*.app -type d -name MacOS); do
  if [ -d "$mkvdir" ]; then
    MKVTOOLNIX_BIN_PATH=$(realpath $mkvdir)/
    echo MKVToolNix found: ${MKVTOOLNIX_BIN_PATH}
  fi
done 2>/dev/null
if [[ -z ${MKVTOOLNIX_BIN_PATH} ]]; then
	echo ERROR in finding MKVToolNix\*.app
  echo Please install the app into ${APP_DIR}
  MISSING_TOOLS=TRUE
fi

# Check ffmpeg installed path
echo
if [ ! -f "$FFMPEG_BIN" ]; then
  echo ERROR in finding ffmpeg
  echo Please make sure the binary is okay at ${FFMPEG_BIN}
  MISSING_TOOLS=TRUE
else
  echo ffmpeg found: ${FFMPEG_BIN}
fi

# Check ffprobe installed path
#echo
#if [ ! -f "$FFPROBE_BIN" ]; then
#  echo ERROR in finding ffprobe
#  echo Please make sure the binary is okay at ${FFPROBE_BIN}
#  MISSING_TOOLS=TRUE
#else
#  echo ffprobe found: ${FFPROBE_BIN}
#fi

# Check hdr10plus_tool installed path
echo
if [ ! -f "$HDR10PLUS_TOOL_BIN" ]; then
  echo ERROR in finding hdr10plus_tool
  echo Please make sure the binary is okay at ${HDR10PLUS_TOOL_BIN}
  MISSING_TOOLS=TRUE
else
  echo hdr10plus_tool found: ${HDR10PLUS_TOOL_BIN}
fi

# Check dovi_tool installed path
echo
if [ ! -f "$DOVI_TOOL_BIN" ]; then
  echo ERROR in finding dovi_tool
  echo Please make sure the binary is okay at ${DOVI_TOOL_BIN}
  MISSING_TOOLS=TRUE
else
  echo dovi_tool found: ${DOVI_TOOL_BIN}
fi

# Check mp4muxer installed path
#echo
#if [ ! -f "$MP4MUXER_BIN" ]; then
#  echo ERROR in finding mp4muxer
#  echo Please make sure the binary is okay at ${MP4MUXER_BIN}
#  MISSING_TOOLS=TRUE
#else
#  echo mp4muxer found: ${MP4MUXER_BIN}
#fi

# Check suffix of target file name
if [ -z "$OUTPUT_DV_SUFFIX" ]; then
  echo
  echo ERROR in setting "OUTPUT_DV_SUFFIX" variable
  echo Please make sure the variable is not empty
  exit 1
fi
if [ -z "$OUTPUT_HDR10PLUS_SUFFIX" ]; then
  echo
  echo ERROR in setting "OUTPUT_HDR10PLUS_SUFFIX" variable
  echo Please make sure the variable is not empty
  exit 1
fi

if [ -n "${MISSING_TOOLS}" ]; then
  exit 1
fi


## Check and request for the dv/hdr10plus video and the source video files
tput bold ; echo ; echo '♻️  ' 'Checking required input files' ; tput sgr0
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
echo
echo Current Path: ${SCRIPTPATH}
echo
if [[ -z $1 ]]; then
  tput bold ; echo ; echo '♻️  ' 'Input full path of source video 1 (.mkv/.mp4) : ' ; tput sgr0
  tput bold ; echo ; echo '   ' '( Its dv/hdr10plus metadata would be extracted )' ; tput sgr0
  echo
  echo '   Tips: You can drag and drop a file here in order to'
  echo '         input the full path of a file.'
  echo
	read -p "Your input : " HDR_VIDEO
else
	HDR_VIDEO="$1"
fi
if [ ! -f "$HDR_VIDEO" ]; then
  echo
  echo ERROR in finding "$HDR_VIDEO"
  echo Please make sure the path is correct!
  exit 1
fi
FILENAME=$(basename "$HDR_VIDEO")
BASENAME="${FILENAME%.[^.]*}"
EXTENSION=$(echo "${FILENAME:${#BASENAME} + 1}" | tr '[:upper:]' '[:lower:]')
if [[ "${EXTENSION}" != "mkv" && "${EXTENSION}" != "mp4" ]]; then
  echo
  echo ERROR in reading "$HDR_VIDEO"
  echo Please make sure the file is .mkv/.mp4
  exit 1
fi
echo
if [[ -z $2 ]]; then
  tput bold ; echo ; echo '♻️  ' 'Input full path of source video 2 (.mkv/.mp4) : ' ; tput sgr0
  tput bold ; echo ; echo '    ' '( Its video and audio would be copied )' ; tput sgr0
  echo
  echo '   Tips: You can drag and drop a file here in order to'
  echo '         input the full path of a file.'
  echo
	read -p "Your input : " SOURCE_VIDEO
else
	SOURCE_VIDEO="$2"
fi
if [ ! -f "$SOURCE_VIDEO" ]; then
  echo
  echo ERROR in finding "$SOURCE_VIDEO"
  echo Please make sure the path is correct!
  exit 1
fi
FILENAME=$(basename "$SOURCE_VIDEO")
BASENAME="${FILENAME%.[^.]*}"
EXTENSION=$(echo "${FILENAME:${#BASENAME} + 1}" | tr '[:upper:]' '[:lower:]')
if [[ "${EXTENSION}" != "mkv" && "${EXTENSION}" != "mp4" ]]; then
  echo
  echo ERROR in reading "$SOURCE_VIDEO"
  echo Please make sure the file is .mkv/.mp4
  exit 1
fi
echo
# Set output folder path
if [[ -z ${OUTPUT_FOLDER} && -z $3 ]]; then
  tput bold ; echo ; echo '♻️  ' 'Input full path of output (work) folder : ' ; tput sgr0
  tput bold ; echo ; echo '    ' '( Empty means using the same folder as source video 2 )' ; tput sgr0
  echo
  echo '   Tips: You can drag and drop a folder here in order to'
  echo '         input the full path of a folder.'
  echo '         Or just press ENTER key to let the input empty.'
  echo
	read -p "Your input : " OUTPUT_FOLDER
  if [[ -z ${OUTPUT_FOLDER} ]]; then
    OUTPUT_FOLDER=$(dirname "$SOURCE_VIDEO")
  fi
else
  if [[ ! -z $3 ]]; then
  	OUTPUT_FOLDER="$3"
  fi
fi
OUTPUT_FOLDER=${OUTPUT_FOLDER%/}
if [ ! -d "$OUTPUT_FOLDER" ]; then
  echo
  echo ERROR in finding "$OUTPUT_FOLDER"/
  echo Please make sure the folder path is correct!
  exit 1
fi
# Set target video path
FILENAME=$(basename "$SOURCE_VIDEO")
BASENAME="${FILENAME%.[^.]*}"
EXTENSION=$(echo "${FILENAME:${#BASENAME} + 1}" | tr '[:upper:]' '[:lower:]')
TARGET_VIDEO=${OUTPUT_FOLDER}/${BASENAME}


# Function: CleaningExtractedFiles
# Description: To clean up temporary extracted files.
# Return: Nil
CleaningExtractedFiles()
{
    tput bold ; echo ; echo '♻️  ' 'Cleaning up those extracted files' ; tput sgr0
    if [ -f "${HDR_NAME}.DHDR-SRC.hevc" ]; then
      rm -f "${HDR_NAME}.DHDR-SRC.hevc"
    fi
    if [ -f "${HDR_NAME}.DV-RPU.bin" ]; then
      rm -f "${HDR_NAME}.DV-RPU.bin"
    fi
    if [ -f "${HDR_NAME}.HDR10PLUS.json" ]; then
      rm -f "${HDR_NAME}.HDR10PLUS.json"
    fi
    if [ -f "${SOURCE_NAME}.SRC.hevc" ]; then
      rm -f "${SOURCE_NAME}.SRC.hevc"
    fi
    if [ -f "${SOURCE_HEVC}" ]; then
      rm -f "${SOURCE_HEVC}"
    fi
    if [ -f "${TARGET_VIDEO}.hevc" ]; then
      rm -f "${TARGET_VIDEO}.hevc"
    fi
}


# Function: CleaningExtractedFilesOnError
# Description: To clean up temporary extracted files after error occurs.
# Return: Nil
CleaningExtractedFilesOnError()
{
  CLEAN_UP_ON_ERROR=$(echo "${CLEAN_UP_ON_ERROR}" | tr '[:lower:]' '[:upper:]')
  if [[ "${CLEAN_UP_ON_ERROR}" == "TRUE"  ]]; then
    echo
    CleaningExtractedFiles
  fi
}


## Extract dv/hdr10plus metadata from the dv/hdr10plus video
tput bold ; echo ; echo '♻️  ' 'Extracting hevc track from the dv/hdr10plus video' ; tput sgr0
FILENAME=$(basename "$HDR_VIDEO")
BASENAME="${FILENAME%.[^.]*}"
EXTENSION=$(echo "${FILENAME:${#BASENAME} + 1}" | tr '[:upper:]' '[:lower:]')
HDR_NAME=${OUTPUT_FOLDER}/${BASENAME}
# Extract hevc track from mkv file
if [[ "${EXTENSION}" == "mkv" ]]; then
  LINECOUNT=$(${MKVTOOLNIX_BIN_PATH}/mkvinfo "$HDR_VIDEO" | grep -e 'track ID' -e 'Codec ID' | wc -l)
  echo $LINECOUNT
  for ((i=1; i<=LINECOUNT; i++)); do
    TRACKID=$(${MKVTOOLNIX_BIN_PATH}/mkvinfo "$HDR_VIDEO" | grep -e 'track ID' -e 'Codec ID' | head -n $i | tail -n 1 | awk '{print $12;}' | sed 's/)//g')
    let i++
    CODECID=$(${MKVTOOLNIX_BIN_PATH}/mkvinfo "$HDR_VIDEO" | grep -e 'track ID' -e 'Codec ID' | head -n $i | tail -n 1 | awk '{print $5;}' | sed 's/)//g')
    if [[ "${CODECID}" == *"HEVC"* ]]; then
      ${MKVTOOLNIX_BIN_PATH}/mkvextract "$HDR_VIDEO" tracks ${TRACKID}:"${HDR_NAME}.DHDR-SRC.hevc"
      if [ $? -ne 0 ]; then
        echo ERROR on extracing hevc track.
        CleaningExtractedFilesOnError
        exit 1
      fi
      break
    fi
  done
fi
# Extract hevc track from mp4 file
if [[ "${EXTENSION}" == "mp4" ]]; then
  ${FFMPEG_BIN} -y -i "$HDR_VIDEO" -map 0:v:0 -c:v copy -bsf:v hevc_mp4toannexb -f hevc -tag:v hvc1 "${HDR_NAME}.DHDR-SRC.hevc"
  if [ $? -ne 0 ]; then
    echo ERROR on extracing hevc track.
    CleaningExtractedFilesOnError
    exit 1
  fi
fi
# Extract dv metadata from the extracted hevc track
if [ -f "${HDR_NAME}.DHDR-SRC.hevc" ]; then
  tput bold ; echo ; echo '♻️  ' 'Extracting dv metadata from the dv/hdr10plus hevc track' ; tput sgr0
  ${DOVI_TOOL_BIN} extract-rpu -i "${HDR_NAME}.DHDR-SRC.hevc" -o "${HDR_NAME}.DV-RPU.bin"
fi
if [ -f "${HDR_NAME}.DV-RPU.bin" ]; then
  FILESIZE=$(stat -f%z "${HDR_NAME}.DV-RPU.bin")
  if [[ $(bc <<< "${FILESIZE} == 0") -eq 1 ]]; then
    echo "${HDR_NAME}.DV-RPU.bin" contains no dv metadata.
    echo
    rm -f "${HDR_NAME}.DV-RPU.bin"
    echo dv metadata file is removed.
  fi
fi
# Extract hdr10plus metadata from the extracted hevc track
if [ -f "${HDR_NAME}.DHDR-SRC.hevc" ]; then
  tput bold ; echo ; echo '♻️  ' 'Extracting hdr10plus metadata from the dv/hdr10plus hevc track' ; tput sgr0
  ${HDR10PLUS_TOOL_BIN} extract -i "${HDR_NAME}.DHDR-SRC.hevc" -o "${HDR_NAME}.HDR10PLUS.json"
fi
if [ -f "${HDR_NAME}.HDR10PLUS.json" ]; then
  FILESIZE=$(stat -f%z "${HDR_NAME}.HDR10PLUS.json")
  if [[ $(bc <<< "${FILESIZE} == 0") -eq 1 ]]; then
    echo ERROR! "${HDR_NAME}.HDR10PLUS.json" contains no hdr10plus metadata.
    echo
    rm -f "${HDR_NAME}.HDR10PLUS.json"
    echo hdr10plus metadata file is removed.
  fi
fi
# Check if eithor dv or hdr10plus metadata exists
if [[ (! -f "${HDR_NAME}.DV-RPU.bin") && (! -f "${HDR_NAME}.HDR10PLUS.json") ]]; then
  echo ERROR! No dv/hdr10plus metadata is extracted.
  echo
  CleaningExtractedFilesOnError
  exit 1
fi


## Extract hevc track from the source video 2
## and then inject dv/hdr10plus metadata and output to a new hevc track
tput bold ; echo ; echo '♻️  ' 'Extracting hevc track from the source video 2' ; tput sgr0
FILENAME=$(basename "$SOURCE_VIDEO")
BASENAME="${FILENAME%.[^.]*}"
EXTENSION=$(echo "${FILENAME:${#BASENAME} + 1}" | tr '[:upper:]' '[:lower:]')
SOURCE_NAME=${OUTPUT_FOLDER}/${BASENAME}
# Extract hevc track from mkv file
if [[ "${EXTENSION}" == "mkv" ]]; then
  LINECOUNT=$(${MKVTOOLNIX_BIN_PATH}/mkvinfo "$SOURCE_VIDEO" | grep -e 'track ID' -e 'Codec ID' | wc -l)
  for ((i=1; i<=LINECOUNT; i++)); do
    TRACKID=$(${MKVTOOLNIX_BIN_PATH}/mkvinfo "$SOURCE_VIDEO" | grep -e 'track ID' -e 'Codec ID' | head -n $i | tail -n 1 | awk '{print $12;}' | sed 's/)//g')
    let i++
    CODECID=$(${MKVTOOLNIX_BIN_PATH}/mkvinfo "$SOURCE_VIDEO" | grep -e 'track ID' -e 'Codec ID' | head -n $i | tail -n 1 | awk '{print $5;}' | sed 's/)//g')
    if [[ "${CODECID}" == *"HEVC"* ]]; then
      ${MKVTOOLNIX_BIN_PATH}/mkvextract "$SOURCE_VIDEO" tracks ${TRACKID}:"${SOURCE_NAME}.SRC.hevc"
      if [ $? -ne 0 ]; then
        echo ERROR on extracing hevc track.
        CleaningExtractedFilesOnError
        exit 1
      fi
      break
    fi
  done
fi
# Extract hevc track from mp4 file
if [[ "${EXTENSION}" == "mp4" ]]; then
  ${FFMPEG_BIN} -y -i "$SOURCE_VIDEO" -map 0:v:0 -c:v copy -bsf:v hevc_mp4toannexb -f hevc -tag:v hvc1 "${SOURCE_NAME}.SRC.hevc"
  if [ $? -ne 0 ]; then
    echo ERROR on extracing hevc track.
    CleaningExtractedFilesOnError
    exit 1
  fi
fi
# Inject dv/hdr10plus metadata to the extracted hevc track
if [ -f "${SOURCE_NAME}.SRC.hevc" ]; then
  SOURCE_HEVC=${SOURCE_NAME}.SRC.hevc
  SKIP_INJECT_DV=
  if [ -f "${HDR_NAME}.DV-RPU.bin" ]; then
    REPLACE_DV_METADATA=$(echo "${REPLACE_DV_METADATA}" | tr '[:lower:]' '[:upper:]')
    if [[ "${REPLACE_DV_METADATA}" != "TRUE"  ]]; then
      tput bold ; echo ; echo '♻️  ' 'Testing dv metadata on the hevc track of source video 2' ; tput sgr0
      ${DOVI_TOOL_BIN} extract-rpu -i "${SOURCE_HEVC}" -o "${SOURCE_HEVC}.DV-RPU.bin"
      if [ -f "${SOURCE_HEVC}.DV-RPU.bin" ]; then
        FILESIZE=$(stat -f%z "${SOURCE_HEVC}.DV-RPU.bin")
        if [[ $(bc <<< "${FILESIZE} == 0") -eq 0 ]]; then
          SKIP_INJECT_DV="TRUE"
          echo
          echo '   dv metadata is FOUND on the hevc track of source video 2.'
          echo '   The copy of source video 2 will not be injected with dv metadata'
          echo '   from source video 1.'
          echo
        fi
        rm -f "${SOURCE_HEVC}.DV-RPU.bin"
      fi
    fi
    if [ -z "${SKIP_INJECT_DV}" ]; then
      tput bold ; echo ; echo '♻️  ' 'Injecting dv metadata and outputing to a new hevc track' ; tput sgr0
      ${DOVI_TOOL_BIN} inject-rpu -i "${SOURCE_HEVC}" --rpu-in "${HDR_NAME}.DV-RPU.bin" -o "${TARGET_VIDEO}${OUTPUT_DV_SUFFIX}.hevc"
      if [ $? -ne 0 ]; then
        echo ERROR on injecting dv metadata.
        CleaningExtractedFilesOnError
        exit 1
      fi
      SOURCE_HEVC=${TARGET_VIDEO}${OUTPUT_DV_SUFFIX}.hevc
      TARGET_VIDEO=${TARGET_VIDEO}${OUTPUT_DV_SUFFIX}
    fi
  else
    SKIP_INJECT_DV="TRUE"
  fi
  SKIP_INJECT_HDR10PLUS=
  if [ -f "${HDR_NAME}.HDR10PLUS.json" ]; then
    REPLACE_HDR10PLUS_METADATA=$(echo "${REPLACE_HDR10PLUS_METADATA}" | tr '[:lower:]' '[:upper:]')
    if [[ "${REPLACE_HDR10PLUS_METADATA}" != "TRUE"  ]]; then
      tput bold ; echo ; echo '♻️  ' 'Testing hdr10plus metadata on the hevc track of source video 2' ; tput sgr0
      ${HDR10PLUS_TOOL_BIN} --verify extract -i "${SOURCE_HEVC}"
      if [ $? -eq 0 ]; then
        SKIP_INJECT_HDR10PLUS="TRUE"
        echo
        echo '   hdr10plus metadata is FOUND on the hevc track of source video 2.'
        echo '   The copy of source video 2 will not be injected with hdr10plus'
        echo '   metadata from source video 1.'
        echo
      fi
    fi
    if [ -z "${SKIP_INJECT_HDR10PLUS}" ]; then
      tput bold ; echo ; echo '♻️  ' 'Injecting hdr10plus metadata and outputing to a new hevc track' ; tput sgr0
      ${HDR10PLUS_TOOL_BIN} inject -i "${SOURCE_HEVC}" -j "${HDR_NAME}.HDR10PLUS.json" -o "${TARGET_VIDEO}${OUTPUT_HDR10PLUS_SUFFIX}.hevc"
      if [ $? -ne 0 ]; then
        echo ERROR on injecting hdr10plus metadata.
        CleaningExtractedFilesOnError
        exit 1
      fi
      TARGET_VIDEO=${TARGET_VIDEO}${OUTPUT_HDR10PLUS_SUFFIX}
    fi
  else
    SKIP_INJECT_HDR10PLUS="TRUE"
  fi
  if [[ -n "${SKIP_INJECT_DV}" && -n "${SKIP_INJECT_HDR10PLUS}" ]]; then
    echo ERROR! Both dv/hdr10plus metadata injections are not done on source video 2
    echo because it already contains dv/hdr10plus metadata which is copied.
    echo The replace dv/hdr10plus metadata option on this script is set to FALSE, and
    echo therefore no additional dv/hdr10plus metadata injection is needed.
    echo
    CleaningExtractedFilesOnError
    exit 1
  fi
fi
if [ ! -f "${TARGET_VIDEO}.hevc" ]; then
  echo ERROR! The new hevc track with dv/hdr10plus metadata is not created.
  echo
  CleaningExtractedFilesOnError
  exit 1
fi


## Merge the new hevc track and all tracks except hevc track on the source video 2
## and then output to a new .mkv video file
tput bold ; echo ; echo '♻️  ' 'Merging the new hevc track and all tracks except hevc track from the' ; tput sgr0
tput bold ; echo ; echo '   ' 'source video and outputing to a new .mkv video file' ; tput sgr0
${MKVTOOLNIX_BIN_PATH}/mkvmerge -o "${TARGET_VIDEO}.mkv" "${TARGET_VIDEO}.hevc" --no-video "$SOURCE_VIDEO"
if [ $? -eq 0 ]; then
  echo
  tput bold ; echo ; echo '♻️  ' 'Success! The new video "' ${TARGET_VIDEO}.mkv '" with dv/hdr10plus metadata is created.' ; tput sgr0
  echo
  echo '   Tips: If you want a mp4 file instead of mkv, we recommend using'
  echo '         "Subler" mac app to repack it. It'"'"'s the one we know which can'
  echo '         mux mkv/mp4 to mp4 without breaking the index of atmos audio'
  echo '         and can import the chapter index too.'
  echo

  CLEAN_UP_ON_SUCCESS=$(echo "${CLEAN_UP_ON_SUCCESS}" | tr '[:lower:]' '[:upper:]')
  if [[ "${CLEAN_UP_ON_SUCCESS}" == "TRUE"  ]]; then
    echo
    CleaningExtractedFiles
  fi
else
  echo
  echo ERROR! Fail to make a new .mkv video file.
  CleaningExtractedFilesOnError
  exit 1
fi
echo


exit 0
