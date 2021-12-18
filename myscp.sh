#!/usr/bin/env sh
set -x
echo "$# $@ $0, $1,$2"
if [[ $# -eq 2 ]]; then
    from=$1
    to=$2
    scp -i /c/Users/ddesai/.ssh/caf_icfs_dde.cer $from $to
else
    echo "$0 from <from> <to>"
    echo "$0 junk.txt hci@123.123.23.34:/home/hci/."
fi

