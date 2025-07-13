# Documentation:
#
# python validateRsync.py <output_file> <input_file_1> <input_file_2> ... <input_file_n>
# python validateRsync.py res.txt rsync1.txt rsync2.txt rsync3.txt
#
# The script takes n <input_file>. These files need to be a list file paths where each path is in its own line. 
# The script counts the number of files a given path exists in and writes in to the <output_file> the grouped 
# file paths sorted by the number of files they occur in.

import sys
import os
from collections import defaultdict

# Create a dictionary that matches file paths with number of entries.
# Write the dictionary into the output file.
def process_files(input_files, output_file):
    path_info = defaultdict(lambda: {"count": 0, "files": []})

    for file_name in input_files:
        if not os.path.exists(file_name):
            print(f"File {file_name} does not exist.")
            continue

        with open(file_name, 'r') as f:
            paths = f.readlines()
            paths = [path.strip() for path in paths]
            
            for path in paths:
                path_info[path]["count"] += 1
                if file_name not in path_info[path]["files"]:
                    path_info[path]["files"].append(file_name)
                    
    sorted_paths = sorted(path_info.items(), key=lambda x: (-x[1]["count"], x[0]))

    with open(output_file, 'w') as out_file:
        for path, info in sorted_paths:
            out_file.write(f"{path} - {info['count']} files containing it: {', '.join(info['files'])}\n")

    print(f"Output written to {output_file}")


# Check if at least one input file is provided
if len(sys.argv) < 3:
    print("Usage: python3 validateRsync.py <output_file.txt> <input_file1.txt> <input_file2.txt> ... <input_fileN.txt>")
    sys.exit(1)

# Get the arguments
output_file = sys.argv[1]
input_files = sys.argv[2:]

# Call the function to process the files
process_files(input_files, output_file)
