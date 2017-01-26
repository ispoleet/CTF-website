#!/bin/bash
# ---------------------------------------------------------------------------------------
# CS527 Software Security - Purdue Univ.
# Spring 2017
# Kyriakos Ispoglou (ispo)
#
#
# mailpw.sh
#
# This script sends an email with user's credentials to a specific user. Because this
# script is going to run once, no tunneling is needed. Instead it has to be executed
# inside cs527.cs.purdue.edu.
# ---------------------------------------------------------------------------------------

# exactly 1 argument is needed: username
if [ $# -ne 1 ]; then
    echo "Usage: $0 <username>"
    exit
fi

echo "=--------------------------------------------------------------="
echo "|          CS527 Software Security - Purdue University         |"
echo "|                     Administrator Scripts                    |"
echo "|                                                              |"
echo "|                 Mail credentials to the users                |"
echo "=--------------------------------------------------------------="
echo

USER="$1"                                   # username
PASS="$(cat /var/lib/mysql/usr/$USER)"      # password is in file
MAIL="$1@purdue.edu"                        # username is also the email 

# set email body
BODY=$(cat <<-EOF
Hi,

Welcome to CS527 labs! Your credentials for the lab. are shown below. My apologizes for 
sending passwords as plaintexts, but there is no need to mess with public keys.

Some notes:
1. All flags have the following format: cs527{__SOME_MESSAGE__}. This message is usually
   a stupid sentence or a joke written in script kiddie format. You should always read
   the flag you get. If your flag DOES NOT make sense, it's probably WRONG.

2. Do not brute force flags. There's no change to guess a flag and there's a 1 sec delay for
   every wrong attempt. The only thing you can achieve is to cause problems to our network.

3. Website is not very css responsive. Zoom in can make layout "ugly".

4. If you see anything wrong in the website, please let your "cool" admin know :)

5. Web site is located at: https://cs527.cs.purdue.edu/ (please refer to the TA notes on 
    how to access it)


username: $USER
password: $PASS


Happy Hacking!

Cheers,
-ispo
EOF
)

echo -n "[+] Send an email to $MAIL? [y/n] "; read ok
# if incorrect, abort
if [ "$ok" != "y" ]; then
    echo "[-] Operation canceled. Abort."
    exit
fi

# send email to the user
echo "$BODY" | mail -s "Your credentials for CS527 are here!" \
    -r admin@cs527.cs.purdue.edu $MAIL

echo "[+] Email successfully sent."
echo '[+] Exiting.'
echo '[+] Bye bye :)'
# ---------------------------------------------------------------------------------------
