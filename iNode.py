# Dcoumentation:
#
# ./iNode.py
#
# Has corrently hardcoded parameters
# These parameters are the input file 'pathsFile = "/media/kali/T7/MAImg/POC/SameFilePaths.txt"' and the output file 'with open("iNodeDifferences.txt", "w") as f:'
# The input file is a list of paths (Not starting with /)
# The output file contains all paths that have at least one timestamp changed (ctime, mtime, atime)
#
# Takes a file of paths amd expects two mounted images at /mnt/z0/ and /mnt/z1/
# Then it checks for each path in the pathfile if the timestamps differ


import os
import time
import sys

# Use stat to get the ctime atime and atime of a given path
def get_inode_time(path):
    stat_info = os.stat(path)
    
    ctime = stat_info.st_ctime
    atime = stat_info.st_atime
    mtime = stat_info.st_mtime
    
    return ctime, atime, mtime

def print_diff(diff):
    path, (ctimeA, atimeA, mtimeA), (ctimeB, atimeB, mtimeB) = diff
    diffPattern = "---"
    if(ctimeA != ctimeB):
        diffPattern = 'x' + diffPattern[1:]
    if(atimeA != atimeB):
        diffPattern = diffPattern[0] + 'x' + diffPattern[2:]
    if(mtimeA != mtimeB):
        diffPattern = diffPattern[:2] + 'x'
    
    return (f"Path:{path} Diffpattern:{diffPattern} cA:{time.ctime(ctimeA)} mA:{time.ctime(mtimeA)} aA:{time.ctime(atimeA)}  cB:{time.ctime(ctimeB)} mB:{time.ctime(mtimeB)} aB:{time.ctime(atimeB)}")

# Hardcoded list of filepaths
pathsFile = "/media/kali/T7/MAImg/POC/SameFilePaths.txt"
iNodeDifferences = []

# Opens the file
with open(pathsFile, 'r') as file:
    i = 0
    for line in file:
        line = line.strip()
        i = i + 1
        lineA = "/mnt/z0/" + line
        lineB = "/mnt/z1/" + line
        #ctimeA, atimeA, mtimeA = get_inode_time(lineA)
        timeTripelA = get_inode_time(lineA)
        #ctimeB, atimeB, mtimeB = get_inode_time(lineB)
        timeTripelB = get_inode_time(lineB)
        
        if timeTripelA != timeTripelB:
            iNodeDifferences.append((line, timeTripelA, timeTripelB))

# Print detected differences
if iNodeDifferences:
    with open("iNodeDifferences.txt", "w") as f:
        f.writelines([print_diff(item) + "\n" for item in iNodeDifferences])
print(f"iNodeDifferences.txt created with {len(iNodeDifferences)} differences")
