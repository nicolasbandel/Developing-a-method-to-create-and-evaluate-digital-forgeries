#!/bin/bash
# Documentation:
#
# /GetInodeOffset.sh <filepath_on_img> <img-file>
# /GetInodeOffset.sh /home/usera/Music /dev/loop0
#
# This script takes a path and a mount point and returns the offset of the inode of the file.

export PATH=$PATH:/bin:/usr/bin:/usr/local/bin

if [ $# -ne 2 ]; then
    echo "Usage: $0 <filepath> <device>"
    exit 1
fi

filepath=$1
img_file=$2

# Check if file exists
if [ ! -f "$img_file" ]; then
    echo "File does not exist: $img_file"
    exit 1
fi

inode=$(sudo debugfs -R 'stat '$filepath $img_file 2>/dev/null | grep "Inode:" | awk '{print $2}')
output=$(sudo debugfs -R 'imap <'$inode'>' $img_file 2>/dev/null)

# Extract the block number and offset using grep & awk
block=$(echo "$output" | grep -o 'block [0-9]*' | awk '{print $2}')
offset_hex=$(echo "$output" | grep -o 'offset 0x[0-9a-fA-F]*' | awk '{print $2}')

blocksize=$(sudo debugfs $device -R "stats" $img_file 2>/dev/null | awk '/Block size:/ {print $3}')

res=$((block * blocksize + $((offset_hex))))
echo $res


