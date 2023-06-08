#!/bin/bash
file=$1
# line not start with `#`
zcat $file | awk 'BEGIN{res = "Ascending"; prev = 1}
    NR > 3409 && $2 < prev {res = "Fail at "NR; exit}
    NR >= 3409 {prev = $2}
    END {print res}'

#