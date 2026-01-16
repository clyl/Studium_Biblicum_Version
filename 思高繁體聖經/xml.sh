#!/bin/bash

url="https://www.ccreadbible.org/chinesebible/sigao"
# curl --output index.html ${url}

download=$(basename ${url})
# mkdir ${download}
# cat index.html | \
# grep -o "${url}/[^\"]*\.html" | \
# while read -r url2
# do
# curl --output-dir ${download} --remote-name ${url2}
# done

output="思高聖經.xml"

echo "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" > ${output}
echo "<XMLBIBLE xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" biblename=\"思高聖經\">" >> ${output}

cat index.csv | \
while IFS="," read -r b tcbn tcbsn scbn scbsn bn bsn c url2
do

echo "    <BIBLEBOOK bnumber=\"${b}\" bname=\"${tcbn}\" bsname=\"${tcbsn}\">" >> ${output}

for (( i = 1; i <= ${c}; i++ ))
do

echo "        <CHAPTER cnumber=\"${i}\">" >> ${output}

printf -v url3 "%s_Ch_%d_.html" ${url2%_index.html} ${i}

cat ${download}/${url3} | \
sed -n -e "s|.*<sup>\([^<]*\)</sup>\([^<]*\)</td>.*|            <VERS vnumber=\"\1\">\2</VERS>|p" >> ${output}

echo "        </CHAPTER>" >> ${output}

done

echo "    </BIBLEBOOK>" >> ${output}

done

echo "</XMLBIBLE>" >> ${output}

