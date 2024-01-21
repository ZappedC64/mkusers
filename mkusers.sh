#!/bin/bash
# This script creates a new user on the target servers based on a template user
# Author: Raj Wurttemberg
# Date: 20-Jan-2024
# Version: 1.0
# Usage: mkusers.sh -f <filename>
# -f <filename> is the name of the csv file that contains the user data
# The csv file should be in the following format: username,templateuser,servername

# Function to print help text
helptext() {
  echo "Usage: mkusers.sh -f <filename>"
  exit 1
}

# Get admins username for ssh
echo -e "\nThis user account will be used to ssh to the target servers."
echo -n "Enter your username: "
read -r admuser

# declare array to hold the csv data
declare -a CSVDATA

# Parse command line arguments. Get file name or -h for help.
VALID_ARGUMENTS=$# # Returns the count of arguments that are in short or long options
if [ "$VALID_ARGUMENTS" -eq 0 ]; then
  helptext
fi

while getopts ":f:h" opt; do
  case $opt in
    f)
      FILENAME=$OPTARG
      ;;
    h)
      echo "Usage: mkusers.sh -f <filename>"
      exit 1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      helptext
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      helptext
      ;;
  esac
done

echo "$FILENAME"

# Read csv file into the array CSVDATA with the following format: username,templateuser,servername
IFS=$'\n' read -d '' -r -a CSVDATA < $FILENAME

# #print the data in the array
# for line in "${CSVDATA[@]}"; do
#   echo "$line"
# done

# Loop through the array, ssh to the server using the admin user, get the OS, and add the os to the array CSVDATA
for line in "${CSVDATA[@]}"; do
  # Get the server name from the array
  server=$(echo "$line" | cut -d',' -f3)
  # Print what server we are working on
    echo -n "Logging into [$server]... "
  # Get the OS from the server
    echo -n "Getting OS... "
  os=$(ssh $admuser@$server "uname -s")
     echo -n "OS is $os..."
  # Add the OS to the array
     echo "Adding OS to array... "
  line="$line,$os"
  # Replace the line in the array with the new line
  CSVDATA[$i]="$line"
  # Increment the counter
  ((i++))
done

#print the data in the array
echo -e "\n\nUpdated data in the array...\n"
for line in "${CSVDATA[@]}"; do
  echo "$line"
done
