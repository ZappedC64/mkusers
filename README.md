# mkuserr

This script creates a new user on the target servers based on a template user.

I needed a script that could quickly create local users on RHEL, Solaris, and AIX... the manual process was tedious and took too long.

This script will read in a CSV file containg the user names, servers, template user, and comments for the users to be created. The script will then go out to the remote servers and pull the group membership of the template users.  The groups will be added to the newly created users.

NOTE: This script does assume that you have ssh keys or some athentication method that does not prompt for paswords.  I have not tested what happens if a password prompt is encoutered, but theoretically, it should still work.
