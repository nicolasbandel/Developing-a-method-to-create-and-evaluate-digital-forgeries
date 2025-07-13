# Documentation:
#
# python RemoveDuplicateLines.py <filename>
# python RemoveDuplicateLines.py filteredLines.txt
#
# This script makes sure each line is only once in the file. The script is used to remove multiple entries
# of the same path. This can occure when using the results form idifference2.py
import sys

def remove_duplicate_lines_in_place(filename):
    seen = set()
    with open(filename, 'r') as f:
        lines = f.readlines()

    with open(filename, 'w') as f:
        for line in lines:
            if line not in seen:
                f.write(line)
                seen.add(line)

# Usage: python script.py filename.txt
if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: python RemoveDuplicateLines.py <filename>")
        sys.exit(1)
    
    remove_duplicate_lines_in_place(sys.argv[1])
