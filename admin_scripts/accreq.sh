#!/bin/bash
# ---------------------------------------------------------------------------------------
# CS527 Software Security - Purdue Univ.
# Spring 2017
# Kyriakos Ispoglou (ispo)
#
#
# accreq.sh
#
# This script sends a registration email to the server. Script should run from a
# cs.purdue.edu machine, otherwise mail server won't be accessible.
# ---------------------------------------------------------------------------------------

# This function displays an error properly
error() { 
    RED='\033[0;31m'                        # red
    NC='\033[0m'                            # no color
    echo -e "${RED}[ERROR]${NC} $1" 
    echo
}
# ---------------------------------------------------------------------------------------

echo "=--------------------------------------------------------------="
echo "|          CS527 Software Security - Purdue University         |"
echo "|                        Student Scripts                       |"
echo "|                                                              |"
echo "|                 Account Registration Service                 |"
echo "=--------------------------------------------------------------="
echo

# check if script runs from a *.cs.purdue.edu machine
$(echo `hostname` | grep --invert-match --quiet "cs.purdue.edu") && 
    error "Script should run from a *.cs.purdue.edu machine" && exit

# read first name (required)
while : ; do
    echo -n "[+] Enter your first name: "; read FIRSTNAME
    [[ -z  $FIRSTNAME ]] && error "First name cannot be empty!" || break
done

# read last name (required)
while : ; do
    echo -n "[+] Enter your last name: "; read LASTNAME
    [[ -z  $LASTNAME ]] && error "Last name cannot be empty!" || break
done

# read nickname (optionall)
echo -n "[+] Enter your preferred nickname (it can be empty): "; read NICKNAME

# verify information
echo
echo "You have entered:"
echo "[*] First Name: $FIRSTNAME"
echo "[*] Last Name : $LASTNAME"
echo "[*] Nick Name : $NICKNAME"
echo -n "[+] Is the above information correct? [y/n] "; read ok

# if incorrect, abort
if [ "$ok" != "y" ]; then
    error "Incorrect user information. Abort"
    exit
fi

# send the registration email
BODY=$(cat <<-EOF
---------- START OF RECORD ----------
$FIRSTNAME
$LASTNAME
$NICKNAME
----------- END OF RECORD -----------
EOF
)

echo "$BODY" | mail -s "SoftSec Registration" admin@cs527.cs.purdue.edu
echo "[+] Registration request successfully sent."
# ---------------------------------------------------------------------------------------
