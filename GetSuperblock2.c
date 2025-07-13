/* Documentation:

GetSuperblock2 <filesystem image>
GetSuperblock2 filesystem.img

The script opens the file system recalculates the superblock checksum 
and prints the superblock checksum

*/

#include <stdio.h>
#include <stdlib.h>
#include <ext2fs/ext2fs.h>
#include <stdbool.h>

int main(int argc, char *argv[]) {
    bool printDetails = false;

    if (argc < 2) {
        fprintf(stderr, "Usage: %s <device or filesystem image>\n", argv[0]);
        fprintf(stderr, "Flags:\n");
        fprintf(stderr, "-verbos print more detail\n");
        return 1;
    }
    
    if(argc > 2){
    	if(strcmp(argv[2], "-verbos") == 0){
    	    printDetails = true;
    	}
    }

    const char *device = argv[1];
    ext2_filsys fs;
    errcode_t err;
    struct ext2_super_block *sb;
    uint32_t old_csum, new_csum;

    // Force open the filesystem, ignoring checksum errors
    err = ext2fs_open(device, EXT2_FLAG_IGNORE_CSUM_ERRORS, 0, 0, unix_io_manager, &fs);
    if (err) {
        fprintf(stderr, "Error opening filesystem: %s\n", error_message(err));
        return 1;
    }

    // Get the superblock
    sb = fs->super;
    old_csum = sb->s_checksum;
    
    if(printDetails){
	    if (ext2fs_superblock_csum_verify(fs, sb)) {
		printf("Old Superblock checksum is VALID: 0x%08x\n", old_csum);
	    } else {
		printf("Old Superblock checksum is INVALID! 0x%08x\n", old_csum);
	    }
    }
    

    // Compute new checksum
    ext2fs_superblock_csum_set(fs, sb);  // This updates sb->s_checksum
    new_csum = sb->s_checksum;

    // Verify the checksum
    if (ext2fs_superblock_csum_verify(fs, sb)) {
    	if(printDetails){
        	printf("Superblock checksum is VALID: 0x%08x\n", new_csum);
    	}else{
    		printf("0x%08x\n", new_csum);
    	}
    } else {
    	if(printDetails){
		printf("Superblock checksum is INVALID! Old: 0x%08x, New: 0x%08x\n",
		       old_csum, new_csum);
    	}
    }

    // Close the filesystem
    ext2fs_close(fs);
    return 0;
}
