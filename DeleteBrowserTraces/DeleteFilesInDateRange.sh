#!/bin/bash
# Documentation:
#
# DeleteFilesInDateRange.sh <filesystemimage.img> <reference_fileSystemImage.img> <path> <start_epoch> <end_epoch>
# DeleteFilesInDateRange.sh filesystemimage.img reference_fileSystemImage.img / 1752398738 1752744338
#
# 1. Create a list of files created in the time frame between <start_epoch> and <end_epoch> and are part of the directory <path>
# 2. Delete all files form the list
# 3. Create a list of all parent folder
# 4. Reset the timestamps of all parent folder


# Check for required arguments
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <filesystemimage.img> <reference_fileSystemImage.img> <path> <start_epoch> <end_epoch>"
    exit 1
fi

IMG="$1"
REFERENCE_IMG="$2"
PATH_IN_IMG="$3"
PATH_IN_IMG_ABS=$(realpath -m "$PATH_IN_IMG")
START_EPOCH="$4"
END_EPOCH="$5"

# Create temporary file
TMPFILE=$(mktemp /tmp/fls_output.XXXXXX)
FILTEREDFILE=$(mktemp /tmp/fls_filtered.XXXXXX)
PARENTPATHS=$(mktemp /tmp/fls_parents.XXXXXX)

workdir="${0%/*}" 

# Run fls and store output
fls -m "/" -r "$IMG" > "$TMPFILE"

# Function: Filter by crtime
filter_by_crtime() {
    while IFS= read -r line; do
        # Get crtime (11th field)
        CRTIME=$(echo "$line" | awk -F'|' '{print $11}')
        
        # Skip if crtime is missing or not a number
        if ! [[ "$CRTIME" =~ ^[0-9]+$ ]]; then
            continue
        fi

        if [ "$CRTIME" -ge "$START_EPOCH" ] && [ "$CRTIME" -le "$END_EPOCH" ]; then
       	    PATH_TO_DELETE=$(echo "$line" | awk -F'|' '{print $2}')

            #check if the file has been renamed
            if [[ "$PATH_TO_DELETE" == *"->"* ]]; then
    	        continue
            fi
            
            # remove entries with (deleted-realloc) and (deleted)
            if [[ "$PATH_TO_DELETE" == *"(deleted"* ]]; then
    	        continue
            fi
        
            LINE_ABS=$(realpath -m "$PATH_TO_DELETE")

            if [[ "$LINE_ABS" == "$PATH_IN_IMG_ABS"* && "$LINE_ABS" != "$PATH_IN_IMG_ABS" ]]; then
                #echo "added"
	        echo "$LINE_ABS" >> "$FILTEREDFILE"
    	    fi
        fi
    done < "$TMPFILE"
}

# Function: Mount and delete files
mount_and_delete_paths() {
    DELETE_FILE="$1"
    MOUNTPOINT="/mnt/z0"

    sudo mount -o loop "$IMG" "$MOUNTPOINT"
    if [ $? -ne 0 ]; then
        rmdir "$MOUNTPOINT"
        exit 1
    fi

    while IFS= read -r relpath; do
        TARGET="$MOUNTPOINT$relpath"

        if [ -e "$TARGET" ]; then
            sudo rm -rf "$TARGET"
        fi
    done < "$DELETE_FILE"

    sudo umount "$MOUNTPOINT"
}

# Function: List parentfolder
extract_parent_folders() {
    local file="$1"
    local parents=()

    while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] && continue
        path="${line%/}"
        IFS='/' read -ra parts <<< "$path"

        local parent=""
        for (( i=0; i<${#parts[@]}-1; i++ )); do
            if [ -z "$parent" ]; then
                parent="${parts[i]}"
            else
                parent="$parent/${parts[i]}"
            fi
            parents+=("$parent")
        done
    done < "$file"

    # Print unique parents sorted
    printf "%s\n" "${parents[@]}" | sort -u > "$PARENTPATHS"
}

update_timestamp(){
    IMG="$1"
    path="$2"
    timestamp_type="$3"
    new_timestamp="$4"
    workdir="${0%/*}" 
    INODE_OFFSET=$("$workdir/../UpdateTimestamps.sh" "$IMG" "$path" "$timestamp_type" "$new_timestamp")
}

reset_timestamp(){
    file_path=$1
    STAT_OUTPUT=$(debugfs -R "stat $file_path" "$IMG" 2>/dev/null)

    ACCESS_F=$(echo "$STAT_OUTPUT" | grep 'atime:'  | awk -F '--' '{print $2}' | xargs)
    MODIFY_F=$(echo "$STAT_OUTPUT" | grep 'mtime:'  | awk -F '--' '{print $2}' | xargs)
    CHANGE_F=$(echo "$STAT_OUTPUT" | grep 'ctime:'  | awk -F '--' '{print $2}' | xargs)
    BIRTH_F=$(echo "$STAT_OUTPUT" | grep 'crtime:' | awk -F '--' '{print $2}' | xargs)
    ACCESS_F_EPOCH=$(date -d "$ACCESS_F" +%s 2>/dev/null)
    MODIFY_F_EPOCH=$(date -d "$MODIFY_F" +%s 2>/dev/null)
    CHANGE_F_EPOCH=$(date -d "$CHANGE_F" +%s 2>/dev/null)
    BIRTH_F_EPOCH=$(date -d "$BIRTH_F" +%s 2>/dev/null)

    STAT_OUTPUT=$(debugfs -R "stat $file_path" "$REFERENCE_IMG" 2>/dev/null)

    ACCESS_R=$(echo "$STAT_OUTPUT" | grep 'atime:'  | awk -F '--' '{print $2}' | xargs)
    MODIFY_R=$(echo "$STAT_OUTPUT" | grep 'mtime:'  | awk -F '--' '{print $2}' | xargs)
    CHANGE_R=$(echo "$STAT_OUTPUT" | grep 'ctime:'  | awk -F '--' '{print $2}' | xargs)
    BIRTH_R=$(echo "$STAT_OUTPUT" | grep 'crtime:' | awk -F '--' '{print $2}' | xargs)
    ACCESS_R_EPOCH=$(date -d "$ACCESS_R" +%s 2>/dev/null)
    MODIFY_R_EPOCH=$(date -d "$MODIFY_R" +%s 2>/dev/null)
    CHANGE_R_EPOCH=$(date -d "$CHANGE_R" +%s 2>/dev/null)
    BIRTH_R_EPOCH=$(date -d "$BIRTH_R" +%s 2>/dev/null)


    if [ $ACCESS_F_EPOCH -ne $ACCESS_R_EPOCH ]; then
        # TODO change ts
        echo "$ACCESS_F ----- $ACCESS_R of $file_path at" 
        # this should be atime
        update_timestamp "$IMG" "$file_path" "ctime" "$ACCESS_R"
    fi
    if [ $CHANGE_F_EPOCH -ne $CHANGE_R_EPOCH ]; then
        # TODO change ts
        echo "$CHANGE_F ----- $CHANGE_R of $file_path  ct"
        # this sould be ctime
        update_timestamp "$IMG" "$file_path" "mtime" "$CHANGE_R"
    fi
    if [ $BIRTH_F_EPOCH -ne $BIRTH_R_EPOCH ]; then
        # TODO change ts
        echo "$BIRTH_F ----- $BIRTH_R of $file_path crt"
        update_timestamp "$IMG" "$file_path" "crtime" "$BIRTH_R"
    fi
    if [ $MODIFY_F_EPOCH -ne $MODIFY_R_EPOCH ]; then
        # TODO change ts
        echo "$MODIFY_F ----- $MODIFY_R of $file_path  mt"
        # this should be atime
        update_timestamp "$IMG" "$file_path" "atime" "$MODIFY_R"
    fi
}

reset_parent_folders(){
    local file="$1"
    while IFS= read -r line || [ -n "$line" ]; do
    	echo "$line print"
        [ -z "$line" ] && continue
        file_path="${line%/}"
        res=$(sudo debugfs -R "stat $file_path" "$IMG")
        if [ -z "$res" ]; then
            echo "file $file_path has been deleted"
        else
            reset_timestamp "$file_path"
        fi
    done < "$file"
}

# This creates a list of all files that are a sub path of the given path and in a timerange
filter_by_crtime

# Delete all paths from a given file
mount_and_delete_paths $FILTEREDFILE # "/tmp/fls_filtered.fgPKnT" # $FILTEREDFILE

# Create a list of all parent folders of the deleted paths
extract_parent_folders $FILTEREDFILE "/tmp/fls_filtered.fgPKnT"

# Update the parent folders timestamps (this requires a reference image)
reset_parent_folders "$PARENTPATHS"

exit 0
