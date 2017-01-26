#!/bin/bash
# ---------------------------------------------------------------------------------------
# CS527 Software Security - Purdue Univ.
# Spring 2017
# Kyriakos Ispoglou (ispo)
#
#
# dbops.sh
#
# This script can directly communicate with the DB server. First it sets up an SSH tunnel
# and then executes a mysql command. Currently supported operations are:
#   1. Show full ranking with names
#   2. Add a new user
#   3. Add a new challenge
# ---------------------------------------------------------------------------------------
HOST=mc18.cs.purdue.edu                     # host to tunnel traffic
USR=kispoglo                                # username for $HOST
SRV_KEY=~/.mykeys/id_rsa                    # private key file for *.cs.purdue.edu
PRIVKEY=~/.mykeys/vm0                       # private key file from VM
DBUSR=root                                  # username of DB 
LOC_PRT=9980                                # port to set tunnel
TIMEOUT=3                                   # for how long tunnel will be open


# ---------------------------------------------------------------------------------------
# This function displays an error properly
error() { 
    RED='\033[0;31m'                        # red
    NC='\033[0m'                            # no color
    echo -e "${RED}[ERROR]${NC} $1" 
    echo
}
# ---------------------------------------------------------------------------------------

# The only argument here, is the requested operation in DB
if [ $# -ne 1 ]; then
    echo "Usage: $0 <rank|adduser|addchal>"
    exit
fi


# ---------------------------------------------------------------------------------------
if [ "$1" = "rank" ]; then                  # display current ranking
    echo "[+] Selected operation: Student ranking"

    # craft SQL query
    QUERY="$( cat <<-EOF
        SELECT firstname, lastname, points+bonuspoints AS score 
        FROM users 
        WHERE type='student' 
        ORDER BY score DESC
    EOF
    )"

# ---------------------------------------------------------------------------------------
elif [ "$1" = "adduser" ]; then             # add a new user
    echo "[+] Selected operation: Add user"

    read -p "[+] Enter first name: " FIRSTNAME
    read -p "[+] Enter last name : " LASTNAME
    read -p "[+] Enter username  : " USERNAME
    read -p "[+] Enter nickname  : " NICKNAME

    # make sure that the information is correct
    echo
    echo "You have entered:"
    echo "[*] First Name: $FIRSTNAME"
    echo "[*] Last Name : $LASTNAME"
    echo "[*] Username  : $USERNAME"
    echo "[*] Nick Name : $NICKNAME"
    echo -n "[+] Is the above information correct? [y/n] "; read ok

    # if incorrect, abort
    if [ "$ok" != "y" ]; then
        error "Incorrect user information. Abort"
        exit
    fi

    # craft SQL query
    QUERY="CALL addusr('$FIRSTNAME', '$LASTNAME', '$USERNAME', '$NICKNAME', 'student')"

# ---------------------------------------------------------------------------------------
elif [ "$1" = "addchal" ]; then             # add a new challenge
    echo "[+] Selected operation: Add challenge"

    read -p "[+] Enter ID : "         CID
    read -p "[+] Enter Name : "       NAME
    read -p "[+] Enter Difficulty : " DIFF
    read -p "[+] Enter Flag : "       FLAG
    read -p "[+] Enter Points : "     POINTS
    read -p "[+] Enter Link : "       LINK
    read -p "[+] Enter Description: " DESCR
    read -p "[+] Enter Hint : "       HINT

    # make sure that the information is correct
    echo
    echo "You have entered:"
    echo "[*] ID          : $CID"
    echo "[*] Name        : $NAME"
    echo "[*] Difficulty  : $DIFF"
    echo "[*] Flag        : $FLAG"
    echo "[*] Points      : $POINTS"
    echo "[*] Link        : $LINK"
    echo "[*] Description : $DESCR"
    echo "[*] Hint        : $HINT"
    echo -n "[+] Is the above information correct? [y/n] "; read ok

    # if incorrect, abort
    if [ "$ok" != "y" ]; then
        error "Incorrect challenge information. Abort"
        exit
    fi

    # craft SQL query
    QUERY="$( cat <<-EOF
        INSERT INTO challenges
            (cid,name,difficulty,flaghash,initpoints,link,description,hint) 
        VALUES (
            $CID, '$NAME', '$DIFF', '$FLAG', $POINTS, '$LINK', '$DESCR', '$HINT'
        )
    EOF
    )"
    
# ---------------------------------------------------------------------------------------
else                                        # sink: unknown option
    error "Unknown option!"
    echo "Usage: $0 <rank|adduser|addchal>"
    echo
    exit                                    # abort
fi

# ---------------------------------------------------------------------------------------
echo -e "[+] Connecting to DB server. Default username is set to '$USER'."
read -sp "[+] Enter password: " PASSWD      # don't echo characters

echo -e "[+] Setting up up a tunnel to '$HOST:$LOC_PORT'."
echo -e "[+] Tunnel will be active for $TIMEOUT seconds"
ssh  -L $LOC_PRT:cs527-vm0.cs.purdue.edu:22 -f -i $SRV_KEY $USR@mc18.cs.purdue.edu \
        "sleep $TIMEOUT"

echo "[+] MySQL output:"
echo
echo
# when execute the mysql command you'll get the following warning:
#   "Warning: Using a password on the command line interface can be insecure."
# If you want to avoid that, append the stderr redirection. However you might
# miss other errors, like access denied, etc. (Hint: don't use spaces between 
# -p and password)
ssh cs527@localhost -p$LOC_PRT -i $PRIVKEY \
    "mysql -t -u $DBUSR -p$PASSWD -D cs527_ctf -e \"$QUERY\" " #2> /dev/null"

# add a safe delay until tunnel gets closed
echo
echo
echo "[+] Waiting until tunnel gets closed ($((TIMEOUT-1)) seconds)..."
sleep $((TIMEOUT-1))

echo '[+] Exiting.'
echo '[+] Bye bye :)'
# ---------------------------------------------------------------------------------------
