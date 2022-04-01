#!/usr/bin/env sh

set +x

if [[ $# -eq 1 ]]; then
    echo "Checking $1 ==="
    incCnt=$(grep -c -w INCLUDE $1)
    if [[ $incCnt -gt 0 ]]; then
        xlates=$( grep -w -A5 INCLUDE $1|grep FILE|awk '{print $3 }')
        for file in $xlates
        do
            echo "checking include parameter"
            echo "$file included in $1"
            echo "=======
IN params
========="
            grep -B5 "FILE $file" $1|grep -w IN |awk '{for(i=1;i<NF;i++ ) printf(" %s\n", $i ) }'|sed 's/{//g;s/}//g' |grep -v IN
            echo "=======
REPLACE_IN params
================="
            grep -A3 "FILE $file" $1|grep -w REPLACE_IN |awk '{for(i=1;i<NF;i++ ) printf(" %s\n", $i ) }'|sed 's/{//g;s/}//g'|grep -v REPLACE_IN
            echo "=========
OUT params
=========="
            grep -B5 "FILE $file" $1|grep -w OUT |awk '{for(i=1;i<NF;i++ ) printf(" %s\n", $i ) }'|sed 's/{//g;s/}//g'|grep -v OUT
            echo "===========
REPLACE_OUT params
================== "
            grep -A3 "FILE $file" $1|grep -w REPLACE_OUT |awk '{for(i=1;i<NF;i++ ) printf(" %s\n", $i ) }'|sed 's/{//g;s/}//g'|grep -v REPLACE_OUT
        done
    fi

fi
