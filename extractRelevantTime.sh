#!/bin/bash

# Documentation:
#
# ./extractRelevantTime.sh <image_file.img> <path_file.txt> <result.csv>
#
# <image_file.img>: The image file with the metadata
# <path_file.txt>: The list of relevant files
# <result.csv>: The path of the result file
#
# Eg: ./extractRelevantTime.sh FS_POC_BL_1.img ./Rsync/BT1.txt ./fls/BL_1_Timeline.csv
#
# This script extracts all timestamps form the image file.
# Removes all timestamps of files that are not of interest
# Sorts the timestamps into a timeline

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <image_file.img> <path_file.txt> <result.csv>"
    exit 1
fi

# Assign arguments to variables
image_file="$1"
path_file="$2"
result_file="$3"

# Check if the image file exists
if [ ! -f "$image_file" ]; then
    echo "Error: Image file '$image_file' not found."
    exit 1
fi

if [ ! -f "$path_file" ]; then
    echo "Error: Text file '$path_file' not found."
    exit 1
fi

# Create a temporary file for the output
tmp_file=$(mktemp /tmp/fls_output.XXXXXX.txt)
tmp_file_short=$(mktemp /tmp/fls_output.XXXXXX.txt)

# Run fls on the image file and redirect output to the specified text file
echo "Running fls on '$image_file' and saving output to '$tmp_file'..."
fls -r -m / "$image_file" > "$tmp_file"

total_lines=$(wc -l < "$tmp_file")
current_line=0
echo "$total_lines lines int tmp"

# Remove not relevant line 
echo "Checking for matching lines in '$path_file'..."
while IFS= read -r line; do
    current_line=$((current_line + 1))
    # Extract substring between first and second '|'
    path=$(echo "$line" | awk -F'|' '{if (NF>=3) print $2}')
    #echo "$path"
    if grep -qE "^${path:1}(/)?$" "$path_file"; then
        echo "Match found: $line"
        echo "$line" >> $tmp_file_short
    fi
    
    progress=$((current_line * 100 / total_lines))
    echo -ne "Progress: $progress% \r"
done < "$tmp_file"

echo "done"

lines=$(wc -l < "$tmp_file_short")
echo "no lines $lines"

mactime -b "$tmp_file_short" > "$result_file"

# Delete the temporary file
rm -f "$tmp_file"

# Check if fls was successful
if [ $? -eq 0 ]; then
    echo "Success."
else
    echo "Error: Failed to run fls on '$image_file'."
    exit 1
fi 
