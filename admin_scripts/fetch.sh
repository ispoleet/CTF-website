#!/bin/bash
# ---------------------------------------------------------------------------------------
# CS527 Software Security - Purdue Univ.
# Spring 2017
# Kyriakos Ispoglou (ispo)
#
#
# fetch.sh
#
# This script gets connected to the IMAPS server and fetches all emails. From each email
# we strip out all unneeded information and we only keep Date, Origin, Subject, 
# Firstname, Lastname and Username.
# ---------------------------------------------------------------------------------------
# When using localhost, make sure ssh tunneling is enabled:
# sudo ssh kispoglo@mc18.cs.purdue.edu -L 993:cs527.cs.purdue.edu:993 -N -i ~/.mykeys/id_rsa
#HOST=localhost                             # IMAP server to connect to
HOST=cs527.cs.purdue.edu                    # IMAP server to connect to
USER=admin                                  # hardcode username

echo "=--------------------------------------------------------------="
echo "|          CS527 Software Security - Purdue University         |"
echo "|                     Administrator Scripts                    |"
echo "|                                                              |"
echo "|                     Fetch Account Requests                   |"
echo "=--------------------------------------------------------------="
echo

echo -e "[+] Default server is '$HOST'."
echo -e "[+] Default username is set to '$USER'."
echo -n "[+] Enter password: "
read -s PASSWD                              # don't echo characters

echo
echo "[+] Verifying your password. It might take a while..."

# ---------------------------------------------------------------------------------------
# This function displays an error properly
error() { 
    RED='\033[0;31m'                        # red
    NC='\033[0m'                            # no color
    echo -e "${RED}[ERROR]${NC} $1" 
    echo
}

# ---------------------------------------------------------------------------------------
IMAP_1() {                                  # query the number of emails in INBOX
    echo "i1 LOGIN $USER $PASSWD"
    echo "i2 EXAMINE INBOX"
    echo "i3 LOGOUT"

    # connection is closed when the input ends, so sleep for a while to not stuck
    sleep 1
    echo "i4 LOGOUT"                        
}

# ---------------------------------------------------------------------------------------
IMAP_2() {                                  # fetch all emails from INBOX
    echo "i1 LOGIN $USER $PASSWD"
    echo "i2 EXAMINE INBOX"

    # If you fetch all emails at once it's hard to separate them in stdout
    # echo "i3 FETCH 1:$(($1)) (BODY[HEADER.FIELDS (DATE FROM SUBJECT)] BODY[TEXT])"
    
    for ((i=1; i<=$(($1)); i++))            # fetch them one by one
    do
        echo "i0 NOOP"                      # the output of NOOP is our delimiter
        sleep 1                             # pause to catch NOOP output

        # fetch ith email
        echo "i$(($i+2)) FETCH $(($i)) (BODY[HEADER.FIELDS (DATE FROM SUBJECT)] BODY[TEXT])"
    done

    sleep 1                                 # as before, sleep for a while
    echo "i99 LOGOUT"
}

# ---------------------------------------------------------------------------------------
COUNT_EMAILS() {                            # count the emails 

    # connect to IMAP using SSL and execute 1st script
    IMAP_1 | openssl s_client -crlf -quiet -connect $HOST:imaps 2>/dev/null \
           | while read LINE;               # process output line by line
    do
        # echo "| $LINE"

        # first check if authentication was successful; if return -1 (255)
        if [[ $(echo "$LINE" | grep "AUTHENTICATIONFAILED") ]]; then
            error "Invalid password! Exiting"
            return 255                      # error
        fi

        # Command "i1 EXAMINE INBOX" has an output like this:
        #
        #   * FLAGS (\Answered \Flagged \Deleted \Seen \Draft)
        #   * OK [PERMANENTFLAGS ()] Read-only mailbox.
        #   * 4 EXISTS
        #   * 0 RECENT
        #   * OK [UNSEEN 1] First unseen.
        #   * OK [UIDVALIDITY 1484403187] UIDs valid
        #   * OK [UIDNEXT 5] Predicted next UID
        #   * OK [HIGHESTMODSEQ 8] Highest
        #   i1 OK [READ-ONLY] Examine completed (0.000 secs).
        #
        # The number before "EXISTS" is what we want; grep for it
        if [[ $(echo "$LINE" | grep "EXISTS") ]]; then

            # split line into tokens and grab the 2nd one
            NMAILS=$(echo "$LINE" | awk '{split($0,N," "); print N[2]}')

            echo "[+] $NMAILS mails found in INBOX..."

            return $NMAILS                  # return that number
        fi
    done
}

# ---------------------------------------------------------------------------------------
COUNT_EMAILS                                # execute function 
NMAILS=$?                                   # and get return value
[[ $NMAILS -eq 255 ]] && exit               # if an error returned, abort
    
echo "[+] Fetching all ($NMAILS) emails from server..."

MODE="OFF"                                  # printing mode
CTR=1                                       # mail counter

# connect to IMAP using SSL and execute 2nd script
IMAP_2 NMAILS | openssl s_client -crlf -quiet -connect $HOST:imaps 2>/dev/null \
              | while read LINE;            # process output line by line
do
    # echo "| $LINE"

    # Command "i3 FETCH 2 (BODY[HEADER.FIELDS (DATE FROM SUBJECT)] BODY[TEXT])" has an
    # output like this:
    # 
    #   * 2 FETCH (BODY[HEADER.FIELDS (DATE FROM SUBJECT)] {124}
    #   Date: Sat, 14 Jan 2017 09:17:30 -0500
    #   From: Kyriakos K Ispoglou <kispoglo@cs.purdue.edu>
    #   Subject: SoftSec Registration
    #
    #   BODY[TEXT] {108}
    #   ---------- START OF RECORD ----------
    #   Kyriakos
    #   Ispoglou
    #   ispo
    #   ----------- END OF RECORD -----------
    #   )
    #
    # Command "i4 NOOP" has an output like this:
    #   i4 OK NOOP completed.
    #
    # We use NOOPs as delimiters to distinguish emails. From each email we isolate
    # and we extart all important fields
    if [[ $(echo "$LINE" | grep "NOOP") ]]; then
        
        # a new email       
        echo
        echo "-----=== Mail #$CTR ===-----"
        CTR=$(($CTR+1))                     # increment counter         
        MODE="ON"                           # allow writing
    fi


    # if writing is allowed, print Date, Origin and Subject
    [ "$MODE" = "ON" ] && $(echo "$LINE" | grep --quiet "Subject\|Date\|From") \
                       && echo "$LINE"

    # if you find the end of record disable writing
    if [[ $(echo "$LINE" | grep -e "----------- END OF RECORD -----------") ]]; then
        MODE="OFF"
    fi

    # if you're inside START/END print everything
    [ "$MODE" = "ALL" ] && echo "$LINE"

    # if you find the end of record enable full writing
    if [ "$MODE" = "ON" ] && \
       [[ $(echo "$LINE" | grep -e "---------- START OF RECORD ----------") ]]; then
        MODE="ALL"
    fi
done

echo
echo
echo '[+] All emails fetched successfully.'
echo '[+] Exiting.'
echo '[+] Bye bye :)'
# ---------------------------------------------------------------------------------------
