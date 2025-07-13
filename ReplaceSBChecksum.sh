# ./ReplaceSBChecksum.sh <img-file>
#
# Eg. ./ReplaceSBChecksum.sh x.img
# 
# This script calls the c script that recalculates the superblock checksum and inserts the result into the superblock
# It is needed because the c script did not update the checksum. Some parsing was needed to insert the result of 
# The script correctly


#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <img-file>"
  exit 1
fi

IMG_FILE="$1"

# Get the directory of the current script
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# Call the test.sh script from the same directory
checksum=$("$SCRIPT_DIR/GetSuperblock2" "$IMG_FILE")

# Remove the '0x' prefix
HEX=${checksum#0x}

# Split the hex value into bytes (two characters each)
BYTE1=$(echo "$HEX" | cut -c 7-8)  # Get last 2 characters (5a)
BYTE2=$(echo "$HEX" | cut -c 5-6)  # Get 5th and 6th characters (44)
BYTE3=$(echo "$HEX" | cut -c 3-4)  # Get 3rd and 4th characters (77)
BYTE4=$(echo "$HEX" | cut -c 1-2)  # Get 1st and 2nd characters (c6)

# Format the result in the desired format
hex_value="$BYTE1$BYTE2 $BYTE3$BYTE4"

# converte bytevalues to clear text because the last line does only work with cleartext
clear_text=$(echo "$hex_value" | xxd -r -p)

# repace the current checksum with the new checksum
printf "%b" "$clear_text" | sudo dd of=$IMG_FILE bs=1 seek=2044 count=4 conv=notrunc

