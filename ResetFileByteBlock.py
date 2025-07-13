import os
# Documentation:
#
# python3 ResetFileByteBlock.py <ext4_image_file_to_reset> <ext4_image_file_base> <pos> <count>
# python3 ResetFileByteBlock.py modify.img reference.img 1024 1024
#
# The script reads the a byte block at a given position <pos> for a given length <count> 
# from the <ext4_image_file_to_reset> and inserts it into the same pos in the <ext4_image_file_base>.

import sys

# Read byte block
def read_block(img_file_path, pos, count):
    with open(img_file_path, 'rb') as f:
        f.seek(int(pos))
        block = f.read(int(count))
    return block
    
# Write given block
def write_block(img_file_path, block, pos):
    with open(img_file_path, 'r+b') as f:
        f.seek(int(pos))
        f.write(block)

# Check if the files exist then read and write
def main(img_file_path_reset, img_file_path_base, pos, count):
    if not os.path.isfile(img_file_path_reset):
        print(f"Error: File '{img_file_path_reset}' does not exist.")
        sys.exit(1)
    if not os.path.isfile(img_file_path_base):
        print(f"Error: File '{img_file_path_base}' does not exist.")
        sys.exit(1)
        
    base_block = read_block(img_file_path_base, pos, count)
    
    write_block(img_file_path_reset, base_block, pos)
    
    print(f"Block from '{img_file_path_base}' has been copied to '{img_file_path_reset}'.")

        
     

if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("Usage: python3 ResetFileByteBlock.py <ext4_image_file_to_reset> <ext4_image_file_base> <pos> <count>")
        sys.exit(1)
    
    img_file_path_reset = sys.argv[1]
    img_file_path_base = sys.argv[2]
    pos = sys.argv[3]
    count = sys.argv[4]
    
    main(img_file_path_reset, img_file_path_base, pos, count)
