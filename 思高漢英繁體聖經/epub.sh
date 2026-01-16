#!/bin/bash

url="https://www.ccreadbible.org/chinesebible/nab_nabhtm"
# curl --output index.html ${url}

download=$(basename ${url})
# mkdir ${download}
# cat index.html | \
# grep -o "${url}/[^\"]*\.html" | \
# while read -r url2
# do
# curl --output-dir ${download} --remote-name ${url2}
# done

temp=$(mktemp --directory)
mkdir -p ${temp}/META-INF
mkdir -p ${temp}/OEBPS

ls ${download}/*.html | sort --version-sort | while read -r input
do

t=$(grep -o "<h1>[^<]*</h1>" ${input})
t1=${t#*>}
t2=${t1%</*}
book=${t2%:*}
chapter=${t2#*Chapter }

IFS="," read -r b tcbn tcbsn scbn scbsn bn bsn c url2 < <(grep ${book} index.csv)

printf -v output "${temp}/OEBPS/%02d_%s.xhtml" ${b} ${tcbn}
if [ ! -f "${output}" ]
then
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > ${output}
echo "<html xmlns=\"http://www.w3.org/1999/xhtml\">" >> ${output}
echo "<head>" >> ${output}
echo "<title>${tcbn} ${bn}</title>" >> ${output}
echo "</head>" >> ${output}
echo "<body>" >> ${output}
echo "<h1>${tcbn} ${bn}</h1>" >> ${output}
echo "</body>" >> ${output}
echo "</html>" >> ${output}
fi

printf -v output "${temp}/OEBPS/%02d_%s_%d.xhtml" ${b} ${tcbn} ${chapter}
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > ${output}
echo "<html xmlns=\"http://www.w3.org/1999/xhtml\">" >> ${output}
echo "<head>" >> ${output}
echo "<title>${tcbn} ${bn} : Chapter ${chapter}</title>" >> ${output}
echo "</head>" >> ${output}
echo "<body>" >> ${output}
echo "<h1>${tcbn} ${bn} : Chapter ${chapter}</h1>" >> ${output}

grep -o "<sup>\([0-9]*\)</sup>\([^<]*\)</td>" ${input} | \
sed -n -e "s|.*<sup>\([^<]*\)</sup>\([^<]*\)</td>.*|<p><sup>${chapter}:\1</sup> \2</p>|p" >> ${output}

echo "</body>" >> ${output}
echo "</html>" >> ${output}

done

echo -n "application/epub+zip" > ${temp}/mimetype

cat << 'EOF' > ${temp}/META-INF/container.xml
<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
    <rootfiles>
        <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
    </rootfiles>
</container>
EOF

cat index.csv | \
awk -F "," '
BEGIN {
    print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    print "<html xmlns=\"http://www.w3.org/1999/xhtml\" xmlns:epub=\"http://www.idpf.org/2007/ops\">"
    print "<head>"
    print "    <title>思高聖經</title>"
    print "    <style>"
    print "        nav ol ol li { display: inline; }"
    print "    </style>"
    print "</head>"
    print "<body>"
    print "    <nav epub:type=\"toc\" id=\"toc\">"
    print "        <h1>思高聖經</h1>"
    print "        <ol>"
}

{
    print "            <li>"
    printf "                <a href=\"%02d_%s.xhtml\">%s</a>\n", $1, $2, $2
    print "                <ol>"
    for ( c = 1; c <= $8; c++ ) {
        print "                   <li>"
        printf "                       <a href=\"%02d_%s_%d.xhtml\">%d</a>\n", $1, $2, c, c
        print "                   </li>"
    }
    print "                </ol>"
    print "            </li>"
}

END {
    print "        </ol>"
    print "    </nav>"
    print "</body>"
    print "</html>"
}
' > ${temp}/OEBPS/toc.xhtml

echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > ${temp}/OEBPS/content.opf
echo "<package version=\"3.0\">" >> ${temp}/OEBPS/content.opf

echo "    <metadata xmlns:dc=\"http://purl.org/dc/elements/1.1/\">" >> ${temp}/OEBPS/content.opf
echo "        <dc:title>思高聖經</dc:title>" >> ${temp}/OEBPS/content.opf
echo "    </metadata>" >> ${temp}/OEBPS/content.opf

echo "    <manifest>" >> ${temp}/OEBPS/content.opf
echo "        <item id=\"toc\" href=\"toc.xhtml\" media-type=\"application/xhtml+xml\" properties=\"nav\"/>" >> ${temp}/OEBPS/content.opf

cat index.csv |\
awk -F "," '
BEGIN {
    i = 1
}

{
    printf "        <item id=\"id%04d\" href=\"%02d_%s.xhtml\" media-type=\"application/xhtml+xml\"/>\n", i, $1, $2
    i++
    for ( c = 1; c <= $8; c++ ) {
        printf "        <item id=\"id%04d\" href=\"%02d_%s_%d.xhtml\" media-type=\"application/xhtml+xml\"/>\n", i, $1, $2, c
        i++
    }
}
' >> ${temp}/OEBPS/content.opf

echo "    </manifest>" >> ${temp}/OEBPS/content.opf

echo "    <spine>" >> ${temp}/OEBPS/content.opf
echo "        <itemref idref=\"toc\"/>" >> ${temp}/OEBPS/content.opf

cat index.csv |\
awk -F "," '
BEGIN {
    i = 1
}

{
    printf "        <itemref idref=\"id%04d\"/>\n", i
    i++
    for ( c = 1; c <= $8; c++ ) {
        printf "        <itemref idref=\"id%04d\"/>\n", i
        i++
    }
}
' >> ${temp}/OEBPS/content.opf

echo "    </spine>" >> ${temp}/OEBPS/content.opf

echo "</package>" >> ${temp}/OEBPS/content.opf

p=$(pwd)
cd ${temp}
zip -X0 ${p}/思高聖經.epub mimetype
zip -Xr9D ${p}/思高聖經.epub META-INF OEBPS

echo ${temp}

