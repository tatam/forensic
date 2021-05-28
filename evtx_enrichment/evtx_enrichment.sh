#!/bin/bash

if test $# -lt 2 || test $# -gt 3
then
    echo "evtx_enchance hive_software evtx_path"
    exit 1
fi
HIVE_SOFTWARE=$1
EVTX_PATH=$2
DATE=$(/usr/bin/date +%s)

# rename dependencie
BIN_RENAME=$(/usr/bin/which rename)
if [ $? != 0 ]
then
    echo "Script rename not find, install it"
    echo "[PKG] install rename"
    exit 1
fi

# evtxexport dependencie
BIN_EVTXEXPORT=$(/usr/bin/which evtxexport)
if [ $? != 0 ]
then
    echo "Binary evtxexport not find, install it"
    echo "[PKG] install libevtx-utils"
    exit 1
fi

# hivexsh dependencie
BIN_HIVEXSH=$(/usr/bin/which hivexsh)
if [ $? != 0 ]
then
    echo "Binary hivexsh not find, install it"
    echo "[PKG] install libhivex-bin"
    exit 1
fi

# renaming evtx files
echo "Renaming evtx files"
$BIN_RENAME 's/ /-/g' $EVTX_PATH/*
$BIN_RENAME 's/%4/-/g' $EVTX_PATH/*

# directory creation
echo "Creating ${EVTX_PATH}/log-${DATE} directory"
/usr/bin/mkdir $EVTX_PATH/log-$DATE

# converting evtx files
echo "Converting evtx files"
for FILE in $(/usr/bin/ls ${EVTX_PATH}/*.evtx | /usr/bin/awk -F'.' '{print $1}' | /usr/bin/awk -F'/' '{print $NF}')
do
    $BIN_EVTXEXPORT $EVTX_PATH/$FILE.evtx | /usr/bin/sed -e '1,2d' > $EVTX_PATH/log-$DATE/$FILE.log
done

# getting SUIDs
echo "Getting SUIDs"
SUIDS=$(
$BIN_HIVEXSH <<EOF
load $HIVE_SOFTWARE
cd \Microsoft\Windows NT\CurrentVersion\ProfileList
ls
exit
EOF
)

# getting SUIDs names
echo "Getting SUIDs names and log enhancering"
for SUID in $SUIDS
do
SUID_VAL=$(
$BIN_HIVEXSH <<EOF
load $HIVE_SOFTWARE
cd \Microsoft\Windows NT\CurrentVersion\ProfileList\\$SUID
lsval
exit
EOF
)
    NAME=$(echo $SUID_VAL | /usr/bin/awk '{print $1}' | /usr/bin/awk -F'\' '{print $NF}' | /usr/bin/awk -F'"' '{print $1}')
    echo -e "\t$SUID\t$NAME"
    
    # check file where SUID is present
    for FILE in $(/usr/bin/egrep "$SUIDS$" $EVTX_PATH/log-$DATE/* | awk -F':' '{print $1}' | awk -F'/' '{print $NF}' | sort -u)
#    for FILE in $(/usr/bin/egrep "$SUIDS$" $EVTX_PATH/log-1620745470/* | /usr/bin/awk -F':' '{print $1}' | /usr/bin/awk -F'/' '{print $NF}' | /usr/bin/sort -u)
    do
	# enchance log
	/usr/bin/sed -i "s/$SUID/$SUID $NAME/g" $EVTX_PATH/log-$DATE/$FILE
#	/usr/bin/sed -i "s/$SUID/$SUID $NAME/g" $EVTX_PATH/log-1620745470/$FILE
#	echo "/usr/bin/sed -i "s/$SUID/$SUID $NAME/g" $EVTX_PATH/log-1620745470/$FILE"
    done
done
