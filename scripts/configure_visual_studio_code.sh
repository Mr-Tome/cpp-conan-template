#!/bin/bash

gcc_ver=14.1.0
op_sys=windows-x86_64
##VSCode-win32-x64-1.90.1
#let's check the final destination before we actually do anything
destination="$HOME/.configuration-dependencies/cpp-template"
destination_dep="$destination/"

# Search for directories within the parent directory that contain the substring "VSCode-win32-x64"
find "$destination_dep" -type d | grep -E "VSCode-win32-x64"

# To count the number of matches
count=$(find "$destination_dep" -type d | grep -c -E "VSCode-win32-x64")

if [ $count -gt 0 ]; then
	echo "Visual Studio Code already exists."
else
	echo "Downloading Visual Studio Code (stable)"
	# Define the URL of the GCC installer
	url="https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-archive"

	# Define the temporary file to store the downloaded installer
	zip_file=$(mktemp)
	
	# Download the GCC installer
	curl -L -o $zip_file $url

	# Check if the destination directory exists; if not, create it
	if [ -d "$destination" ]; then
		echo "$destination exists"
	else
		echo "making $destination"
		mkdir -p "$destination"
	fi
	echo "Extracting the ZIP archive to the aforementioned destination directory..."
	unzip -q $zip_file -d "$destination/VSCode-win32-x64"
	echo "GCC ZIP archive extracted to $destination/VSCode-win32-x64."

	# Clean up the ZIP file
	echo "Cleaning up the downloaded ZIP file" 
	rm $zip_file
	
fi


