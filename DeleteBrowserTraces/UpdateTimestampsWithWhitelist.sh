#!/bin/bash
# Documentation:
#
# UpdateTimestampsWithThitelist.sh <filesystemimage.img> <white-list> <start_epoch> <end_epoch>
# UpdateTimestampsWithThitelist.sh filesystemimage.img white-list.txt 1749028820 1749028930
#
# The script creates a timeline of all files on the <filesystemimage.img>. then only files that are part of 
# a path form the whitelist file are kept. The whitelist paths need to start with a /. The remaining files
# have their timestamps manipulated to ensure that none of them are inside the time range of <start_epoch> <end_epoch>

# Check for required arguments
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <filesystemimage.img> <white-list> <start_epoch> <end_epoch>"
    exit 1
fi

IMG="$1"
WHITE_LIST="$2"
START_EPOCH="$3"
END_EPOCH="$4"

# Create temporary file
TMPFILE=$(mktemp /tmp/fls_output.XXXXXX)
FILTEREDFILE=$(mktemp /tmp/fls_filtered.XXXXXX)

# Run fls and store output
echo "[*] Running: fls -m \ -r \"$IMG\" > \"$TMPFILE\""
fls -m "/" -r "$IMG" > "$TMPFILE"

echo "[*] Output saved to: $TMPFILE"

is_file_in_whitlist(){
    check_path=$1
    while IFS= read -r line || [ -n "$line" ]; do
    	[ -z "$line" ] && continue  # skip empty lines

    	if [[ "$check_path" == "$line" ]] || [[ "$check_path" == "$line/"* ]]; then
    	    echo "Match found: $line"
    	    return 0
    	fi
    done < "$WHITE_LIST"
    return 1
}

filter_by_crtime() {
    while IFS= read -r line; do
        # Get crtime (11th field)
        CRTIME=$(echo "$line" | awk -F'|' '{print $11}')
        ATIME=$(echo "$line" | awk -F'|' '{print $8}')
        CTIME=$(echo "$line" | awk -F'|' '{print $10}')
        MTIME=$(echo "$line" | awk -F'|' '{print $9}')
        
        # Skip if any time is missing or not a number
        if ! [[ "$CRTIME" =~ ^[0-9]+$ ]]; then
            continue
        fi
        if ! [[ "$ATIME" =~ ^[0-9]+$ ]]; then
            continue
        fi
        if ! [[ "$MTIME" =~ ^[0-9]+$ ]]; then
            continue
        fi
        if ! [[ "$CTIME" =~ ^[0-9]+$ ]]; then
            continue
        fi
        
        
    	PATH_TO_CHECK=$(echo "$line" | awk -F'|' '{print $2}')

    	#check if the file has been renamed
    	if [[ "$PATH_TO_CHECK" == *"->"* ]]; then
    	    continue
    	fi
    
    	# remove entries with (deleted-realloc) and (deleted)
    	if [[ "$PATH_TO_CHECK" == *"(deleted"* ]]; then
    	    continue
    	fi
    	
    	if is_file_in_whitlist "$PATH_TO_CHECK"; then        
    	    if [ "$CRTIME" -ge "$START_EPOCH" ] && [ "$CRTIME" -le "$END_EPOCH" ]; then
                echo "crtime,$PATH_TO_CHECK" >> "$FILTEREDFILE"
    	    fi
	    if [ "$MTIME" -ge "$START_EPOCH" ] && [ "$MTIME" -le "$END_EPOCH" ]; then
                echo "mtime,$PATH_TO_CHECK" >> "$FILTEREDFILE"
    	    fi
	    if [ "$CTIME" -ge "$START_EPOCH" ] && [ "$CTIME" -le "$END_EPOCH" ]; then
                echo "ctime,$PATH_TO_CHECK" >> "$FILTEREDFILE"
    	    fi
	    if [ "$ATIME" -ge "$START_EPOCH" ] && [ "$ATIME" -le "$END_EPOCH" ]; then
                echo "atime,$PATH_TO_CHECK" >> "$FILTEREDFILE"
    	    fi
        fi
    done < "$TMPFILE"
    
    echo "[*] Output saved to: $FILTEREDFILE"
}

update_timestamps(){
    file_path="$2"
    time_type="$1"
    
    STAT_OUTPUT=$(debugfs -R "stat $file_path" $IMG 2>/dev/null)
    local MODIFY=$(echo "$STAT_OUTPUT" | grep 'mtime:'  | awk -F '--' '{print $2}' | xargs)
    local BIRTH=$(echo "$STAT_OUTPUT" | grep 'crtime:' | awk -F '--' '{print $2}' | xargs)
    local CHANGE=$(echo "$STAT_OUTPUT" | grep 'ctime:'  | awk -F '--' '{print $2}' | xargs)
    workdir="${0%/*}" 
    
    # The script does currently not work with paths that contain spaces
    if [ -z  "$CHANGE" ]; then
    	return
    fi
    
    if [ "$time_type" = "atime" ]; then 
    	# set atime to ctime
    	#echo "change a time to $CHANGE"
    	INODE_OFFSET=$("$workdir/../UpdateTimestamps.sh" "$IMG" "$file_path" "ctime" "$CHANGE")
    elif [ "$time_type" = "ctime" ]; then 
    	# set atime to ctime
    	#echo "change c time to $MODIFY"
    	INODE_OFFSET=$("$workdir/../UpdateTimestamps.sh" "$IMG" "$file_path" "mtime" "$MODIFY")
    elif [ "$time_type" = "mtime" ]; then 
    	# set atime to ctime
    	#echo "change m time to $BIRTH"
    	INODE_OFFSET=$("$workdir/../UpdateTimestamps.sh" "$IMG" "$file_path" "atime" "$BIRTH")
    fi
}



#filter_by_crtime

while IFS=',' read -r string path; do
    # Skip empty or malformed lines
    [[ -z "$string" || -z "$path" ]] && continue
    update_timestamps "$string" "$path"
done < $FILTEREDFILE
