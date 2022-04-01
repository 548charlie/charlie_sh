#!/usr/bin/env sh

if [[ $# -eq 1  ]]; then

   grep -w -E  "IN|OUT|COND|FILE"  $1|sed 's/^ *//'|awk '{ if (NF > 4 ) {for (i=1;i<NF;i++ ) printf("%s\n", $i ) } else print $0}' 
fi
