# Documentation:
# 
# python ResetSuperblock.py <file_system_image_to_modify> <reference_file_system_image>
# python ResetSuperblock.py manipulated.img reference.img
#
# The script reads the superblock of a fixed offset from the <reference_file_system_image>
# and inserts it into the superblock of the <file_system_image_to_modify>.

import os
import sys

# Constants for EXT4 Superblock
SUPERBLOCK_OFFSET = 1024  # The typical offset where the superblock is located

# Read Superblock
def read_superblock(img_file_path):
    with open(img_file_path, 'rb') as f:
        f.seek(SUPERBLOCK_OFFSET)
        superblock = f.read(1024)
    return superblock
    
# Raplaces the superblock
def write_superblock(img_file_path, superblock):
    with open(img_file_path, 'r+b') as f:
        f.seek(SUPERBLOCK_OFFSET)
        f.write(superblock)

# Check if the files exist then read and write
def main(img_file_path_reset, img_file_path_base):
    if not os.path.isfile(img_file_path_reset):
        print(f"Error: File '{img_file_path_reset}' does not exist.")
        sys.exit(1)
    if not os.path.isfile(img_file_path_base):
        print(f"Error: File '{img_file_path_base}' does not exist.")
        sys.exit(1)
        
    base_superblock = read_superblock(img_file_path_base)
    
    write_superblock(img_file_path_reset, base_superblock)
    
    print(f"Superblock from '{img_file_path_base}' has been copied to '{img_file_path_reset}'.")

        
     

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 calculate_checksum.py <ext4_image_file_to_reset> <ext4_image_file_base>")
        sys.exit(1)
    
    img_file_path_reset = sys.argv[1]
    img_file_path_base = sys.argv[2]
    
    main(img_file_path_reset, img_file_path_base)
