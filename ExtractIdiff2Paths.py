# Documentation:
# 
# ExtractIdiff2Paths.py <input_file> <output_file>
# ExtractIdiff2Paths.py idiffOutput.idiff path.txt
# 
# The script extracts the paths from the idifference2.py results. The result need to be only form 
# one category such as deleted files or changed properties. 
# The column indext needs to be changed depending on the result section.
# column = 1 #needed for new and deleted
# column = 0 #needed for changed properties

import sys
import os
def extract_urls(input_file, output_file):
    try:
        with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
            for line in infile:
                parts = line.strip().split('\t')
                column = 1 #needed for new and deleted
                #column = 0 #needed for changed properties
                if len(parts) >= column + 1:
                    outfile.write(parts[column] + '\n') 
        print(f"Extracted paths written to: {output_file}")
    except FileNotFoundError:
        print(f"Error: File '{input_file}' not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python ExtractIdiff2Paths.py <input_file> <output_file>")
    else:
        extract_urls(sys.argv[1], sys.argv[2])
