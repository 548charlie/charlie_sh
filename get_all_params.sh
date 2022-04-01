#!/usr/bin/env sh

set +x
filename=""
if [[ $# -eq 1 ]]; then
    filename=$1
fi
if [[ -f $filename ]]; then
echo "*********************************************************************"
incCnt=$(grep -c -w INCLUDE $filename)
echo "Checking $1  $incCnt==="
if [[ $incCnt -gt 0 ]]; then
        xlates=$( grep -w -A5 INCLUDE $1|grep FILE|awk '{print $3 }')
        xlates="$filename $xlates"
        for file in $xlates
        do
            echo "==========================="
            echo "checking include parameter"
            echo "$file included in $1"
            echo "==========================="
            grep -wE "IN|OUT|REPLACE_IN|REPLACE_OUT|COND" $file|sed 's/^ *//'|awk -F\{ '{if ($0 ~ /COND/ ){ print $0 } else if  (NF > 4 ) {for(i=1;i<NF;i++ ) printf("{%s\n", $i ) } else print $0}'
        done
else

            grep -wE "IN|OUT|REPLACE_IN|REPLACE_OUT|COND" $filename|sed 's/^ *//'|awk '{if ($0 ~ /COND/ ){ print $0} else if  (NF > 5 ) {for(i=1;i<NF;i++ ) print $i  } else print $0}'
fi
else
    echo "File $filename does not exist"
fi

