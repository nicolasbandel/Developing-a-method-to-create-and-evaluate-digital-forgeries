# Documentation:
#
# python validateSyslog.py <file_path> <time_delta>
# python validateSyslog.py /var/log/syslog 1
#
# The script reads each line of a given file <file_path>. it is expected that the first part of the line is a timestamp.
# If the timestamp from the current line is in the past compared to the previous line the number of errors is increased and
# the error time is increased by the difference between the two timestamps. The <time_dalta> is an argument that can be used to 
# igonre errors that are smaller then the <time_delta> in seconds.

import datetime
import argparse

def compare_timestamps(file_path, time_delta):
	# Open the log file
	lineNum = 0
	total_timediff = 0
	total_errors = 0
	with open(file_path, 'r') as file:
		# Initialize the previous timestamp as None
		prev_timestamp = None
	
	
		# Loop through each line in the file
		for line in file:
	    		# Extract the timestamp from the start of the line
			timestamp_str = line.split(' ')[0]
			    
			try:
				# Parse the timestamp to a datetime object
				timestamp = datetime.datetime.fromisoformat(timestamp_str)
				
				# If there is a previous timestamp, compare the two
				if prev_timestamp:
					time_diff = timestamp - prev_timestamp
					if time_diff.total_seconds() + time_delta  < 0:
						if total_errors == 0:
							total_timediff = time_diff.total_seconds()
						else:
							total_timediff = total_timediff + time_diff.total_seconds()
						total_errors = total_errors + 1
						print(f"{lineNum} {time_diff.total_seconds()}")
					
				# Update the previous timestamp for the next iteration
				prev_timestamp = timestamp
				lineNum = lineNum + 1
				
			except ValueError as e:
				print(f"Skipping line due to timestamp parsing error: {e}")
				continue
	print(f"{total_errors} errors that lead to an error of {-1 * total_timediff}")

parser = argparse.ArgumentParser(description="validate the syslog file")
parser.add_argument("file_path", help="Path to the file")
parser.add_argument("time_delta", help="allows time difference in seconds")
args = parser.parse_args()
print(str(args.file_path) + " " + str(args.time_delta))
compare_timestamps(args.file_path, int(args.time_delta))
