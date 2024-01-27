#!/bin/bash
# This script creates a new user on the target servers based on a template user
# Author: Raj Wurttemberg
# Date: 27-Jan-2024
# Version: 1.0
# Usage: mkusers.sh -f <filename>
# -f <filename> is the name of the csv file that contains the user data
# The csv file should be in the following format: username,templateuser,servername,comment
# The csv file should not have a header row

# Function to print help text
helptext() {
  echo "Usage: mkusers.sh -f <filename>"
  exit 1
}

# Function to extract users linux group memberships
# Removing any admin groups from the list just in case of shenanigans
extract_group() {
  # Get the user's groups
  groups=$(ssh $admuser@$server "groups $1")
  # Remove the username from the string
  groups=$(echo "$groups" | cut -d':' -f2)
  # Remove the second username from the string
  remote_sed="s/$1//g"
  groups=$(echo "$groups" | sed "$remote_sed")
  # Remove the new line from the string
  groups=$(echo "$groups" | tr -d '\n')
  # Remove the comma from the string
  groups=$(echo "$groups" | tr -d ',')
  # Remove the word "users" from the string
  groups=$(echo "$groups" | sed 's/users//g')
  # Remove the word "wheel" from the string
  groups=$(echo "$groups" | sed 's/wheel//g')
  # Remove the word "root" from the string
  groups=$(echo "$groups" | sed 's/root//g')
  # Remove the word "adm" from the string
  groups=$(echo "$groups" | sed 's/adm//g')
  # Remove the word "systemd-journal" from the string
  groups=$(echo "$groups" | sed 's/systemd-journal//g')
  # Remove the word "systemd-network" from the string
  groups=$(echo "$groups" | sed 's/systemd-network//g')
  # Remove the word "systemd-resolve" from the string
  groups=$(echo "$groups" | sed 's/systemd-resolve//g')
  # Remove the word "systemd-timesync" from the string
  groups=$(echo "$groups" | sed 's/systemd-timesync//g')
  # Remove the word "systemd-coredump" from the string
  groups=$(echo "$groups" | sed 's/systemd-coredump//g')
  # Remove the word "systemd-bus-proxy" from the string
  groups=$(echo "$groups" | sed 's/systemd-bus-proxy//g')
  # Remove the word "systemd-journal-remote" from the string
  groups=$(echo "$groups" | sed 's/systemd-journal-remote//g')
  # Remove the word "systemd-journal-gateway" from the string
  groups=$(echo "$groups" | sed 's/systemd-journal-gateway//g')
  # Remove any extraneous white space from the string
  groups=$(echo "$groups" | xargs)
  # Change spaces to commas in the string
  groups=$(echo "$groups" | tr ' ' ',')
  # Add quotes to the groups string
  groups="\"$groups\"" 
}

create_pw() {
  # Generate a semi-random password
  md5val=$(date +%s | md5sum | cut -c1-8)
  pw=$(echo "P@ssword01-$md5val")
}

# declare array to hold the csv data
declare -a CSVDATA

# Parse command line arguments. Get file name or -h for help.
VALID_ARGUMENTS=$# # Returns the count of arguments that are in short or long options
if [ "$VALID_ARGUMENTS" -eq 0 ]; then
  helptext
fi

# Get admins username for ssh
echo -e "\nThis user account will be used to ssh to the target servers."
echo -n "Enter your username: "
read -r admuser

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

# echo "$FILENAME"

# Read csv file into the array CSVDATA with the following format: username,templateuser,servername,comment
# The csv file should not have a header row
readarray -t CSVDATA < "$FILENAME"

# @@ DEBUG
#print the data in the array
#for line in "${CSVDATA[@]}"; do
#  echo "$line"
#done

# exit 0

# Loop through the array, ssh to the server using the admin user, get the OS, and add the os to the array CSVDATA
for line in "${CSVDATA[@]}"; do
  # Get the server name from the array
  server=$(echo "$line" | cut -d',' -f3)
  # Print what server we are working on
    echo -n "Logging into [$server]. "
  # Get the OS from the server
  os=$(ssh "$admuser@$server" "uname -s")
    echo -n "OS:[$os]. "
  #line="$line,$os"
  # Replace the line in the array with the new line
  #CSVDATA[$i]="$line"
   # Call the extract_group function
  tplu=$(echo "$line" | cut -d',' -f2)
  extract_group "$tplu"
  echo -n "Template groups: [$groups]. "
  # add the os and groups to the array
  echo "Adding OS and groups to array... "
  line="$line,$os,$groups"
  # Replace the line in the array with the new line
  CSVDATA[$i]="$line"
  # Increment the counter
  ((i++))
done

#print the data in the array
# echo -e "\n\nUpdated data in the array...\n"
# for line in "${CSVDATA[@]}"; do
#   echo "$line"
# done

# Create the users on the target servers and add them to the correct groups. OSs are Linux, Solaris, and AIX
# Loop through the array CSVDATA and create the users. Convert quotes in the groups string, to commas
for line in "${CSVDATA[@]}"; do
  # Get the username from the array
  username=$(echo "$line" | cut -d',' -f1)
  # Get the template user from the array
  tplu=$(echo "$line" | cut -d',' -f2)
  # Get the server name from the array
  server=$(echo "$line" | cut -d',' -f3)
  # Get the comment from the array
  comment=$(echo "$line" | cut -d',' -f4)
  # Get the OS from the array
  os=$(echo "$line" | cut -d',' -f5)
  # Get the groups from the array
  groups=$(echo "$line" | cut -d',' -f6)
  # Convert the quotes in the groups string to commas
  groups=$(echo "$groups" | tr -d '"')
  # Print what server we are working on
  echo -n "Logging into [$server]. "
  # Get the template user's groups
  extract_group "$tplu"
  echo -n "Template groups: [$groups]. "
  # Create the password
  create_pw
  echo -n "Password: [$pw]. "
  # Create the user on the server
  if [ "$os" == "Linux" ]; then
    echo "Creating user [$username] on [$server]. "
    ssh "$admuser@$server" "sudo useradd -m -c \"$comment\" -G $groups $username"
    echo " - Setting password for [$username] on [$server]. "
    ssh "$admuser@$server" "echo \"$pw\" | sudo passwd --stdin $username"
    echo " - Setting password to expire for [$username] on [$server]. "
    ssh "$admuser@$server" "sudo chage -d 0 $username"
  elif [ "$os" == "Solaris" ]; then
    echo "Creating user [$username] on [$server]. "
    ssh "$admuser@$server" "sudo useradd -m -c \"$comment\" -G $groups $username"
    echo " - Setting password for [$username] on [$server]. "
    ssh "$admuser@$server" "echo \"$pw\" | sudo passwd --stdin $username"
    echo " - Setting password to expire for [$username] on [$server]. "
    ssh "$admuser@$server" "sudo chage -d 0 $username"
  elif [ "$os" == "AIX" ]; then
    echo "Creating user [$username] on [$server]. "
    ssh "$admuser@$server" "sudo useradd -m -c \"$comment\" -G $groups $username"
    echo " - Setting password for [$username] on [$server]. "
    ssh "$admuser@$server" "echo \"$pw\" | sudo passwd --stdin $username"
    echo " - Setting password to expire for [$username] on [$server]. "
    ssh "$admuser@$server" "sudo chage -d 0 $username"
  elif  [ "$os" != "Linux" ] && [ "$os" != "Solaris" ] && [ "$os" != "AIX" ]; then
    echo -e "\nOS [$os] not supported."
  fi
done
