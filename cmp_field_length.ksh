set -x
#

if [[ $# -ge 2 ]]; then
    site=$1
    version1=$2
    variant1=$3
    version2=$4
    variant2=$5
else
    echo "Usage: $0 <site> <version1> <variant1> <version2> <variant2>" 
    echo "Example: $0 icc_main 2.8 2.8_icc 2.6 2.6_icc"

    exit
    
fi
first_file="first_format"
second_file="second_format"

function get_field_and_length() {
    site=$1
    version1=$2
    varaint1=$3
    version2=$4
    variant2=$5

    root_fmt1=$(echo $fmt1|awk -F/ '{print $0 }' ) 
    root_fmt2=$(echo $fmt2|awk -F/ '{print $0 }' ) 

    first_ids=$(cat ${HCIROOT}/formats/hl7/${version1}/fields)
#|awk -F} '{printf("%s|%s\n", $1, $4)}'|sed 's/\s//g;s/{ITEM//;s/{LEN//')
    second_ids=$(cat ${HCIROOT}/formats/hl7/${version2}/fields)
#|awk -F} '{printf("%s|%s\n",  $1, $4)}'|sed 's/\s//g;s/{ITEM//;s/{LEN//')
    for id in $first_ids
    do
        echo $id >>${first_file} 
    done
    for id in $second_ids
    do
        echo $id >>${second_file} 
    done
    first_ids=$(cat ${HCIROOT}/${site}/formats/hl7/${version1}/${variant1}fields)
#|awk -F} '{printf("%s|%s\n", $1, $4)}'|sed 's/\s//g;s/{ITEM//;s/{LEN//')
    second_ids=$(cat ${HCIROOT}/${site}/formats/hl7/${version2}/${variant2}/fields)
#|awk -F} '{printf("%s|%s\n",  $1, $4)}'|sed 's/\s//g;s/{ITEM//;s/{LEN//')
    for id in $first_ids
    do
        echo $id >>${first_file} 
    done
    for id in $second_ids
    do
        echo $id >>${second_file} 
    done


} 
diff_file="diff_fields"
echo "Process $0 comparing field length of $format1 and $format2 started at `date +%Y-%m-%dT%H%M%S`" 
echo "we are comparing field length of hl7 $format1 and $format2" >${diff_file} 

get_field_and_length $site $version1 $variant1 $version2 $variant2
`sort -u $first_file >tmp1`
`sort -u $second_file >tmp2`

diff -y --suppress-common-lines tmp1 tmp2 >>${diff_file} 
rm $first_file $second_file tmp1 tmp2

echo "Process $0 ended at `date +%Y-%m-%dT%H%M%S` "
echo "Please see ${diff_file} file for differences"

