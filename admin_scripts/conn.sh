#!/bin/bash
# ---------------------------------------------------------------------------------------
# CS527 Software Security - Purdue Univ.
# Spring 2017
# Kyriakos Ispoglou (ispo)
#
#
# conn.sh
#
# This script uses ssh tunneling to allow direct connection to the VMs through a
# *.cs.purdue.edu machine. 
# ---------------------------------------------------------------------------------------
USR=kispoglo                                # username
SRV_KEY=~/.mykeys/id_rsa                    # private key for *.cs.purdue.edu
VMi_KEY=~/.mykeys/vm$1                      # private key for VM
LOC_PRT=9987                                # local port for ssh tunnel
HOST=mc18.cs.purdue.edu                     # host to tunnel traffic

# ---------------------------------------------------------------------------------------
# exactly 1 argument is needed: VM_ID = 0, 1, 2 or 3
if [ $# -ne 1 ] || [[ ! $1 =~ ^[0-3]$ ]]; then
    echo "Usage: $0 [0-3]"
    exit
fi

echo "=--------------------------------------------------------------="
echo "|          CS527 Software Security - Purdue University         |"
echo "|                     Administrator Scripts                    |"
echo "|                                                              |"
echo "|                   Tunnelling to the network                  |"
echo "=--------------------------------------------------------------="
echo
echo "[+] Connection requested to cs527-vm$1.cs.purdue.edu (VM$1)" 
echo "[+] Starting SSH local port forwarding at port $LOC_PRT..."

# old command, when vms where under mc18.cs.purdue.edu
# ssh $USR@mc18.cs.purdue.edu -L $LOC_PRT:127.0.0.1:527$1 -N -i $SRV_KEY &
ssh $USR@mc18.cs.purdue.edu -L $LOC_PRT:cs527-vm$1.cs.purdue.edu:22 -T -N -i $SRV_KEY &
echo "[+] Adding a 'safe' delay until tunnel is being established..."
sleep 3

echo "[+] Ok. Connecting to VM$1..."
ssh cs527@localhost -p$LOC_PRT -i $VMi_KEY

# kill last process executed (in background)
echo '[+] Tearing down tunnel...'
kill $!

# Check if tunnel port is still open (ports in LISTEN state)
# ports from 2nd ssh might be open (in TIME_WAIT) for a while; ignore them
if [[ `netstat -nat | egrep -i "($LOC_PRT).*(LISTEN)$"` ]]; then
    echo "[-] Error! Port is still open!"
fi

echo '[+] Bye bye :)'
# ---------------------------------------------------------------------------------------
