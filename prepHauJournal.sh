#!/bin/bash
#
##############################################################################
# prepHauJournal.sh
#
# Script assumes the following files are in the same directory:
#       1. Zip file of Issue's HTML to be unzipped
#       2. cover.tex LaTeX file with which to generate eBook cover
#       3. eBookCover.png image of background for cover
#       4. eBookCSS.css containing eBook specific CSS for conversion
#
# Also requires the following programs to be installed and available on $PATH
# to fully function:
#       1. TeXLive with latexmk
#       2. Calibre with ebook-convert
#       3. Imagemagick with convert
#
# Script requires four arguments in this order:
#       1. Zip file to be processed
#       2. Volume number of issue
#       3. Number of issue
#       4. Year of issue
# E.g.: ./prepHauJournal.sh hau3.1-HTML5.zip 3 1 2013
#
# Updated: 7/8/16 --MC
##############################################################################

# Store passed arguments
FILE=$1
VOLUME=$(zenity --title="Volume" --text="What volume is this? (For example, if this is issue 6.1, input 6)" --entry)
NUMBER=$(zenity --title="Number" --text="What number is this? (For example, if this is issue 6.1, input 1)" --entry)
YEAR=$(zenity --title="Year" --text="What is the publication year? (Format: YYYY)" --entry)

# Check if folders already exist (i.e., the script has been run before
for fileType in html epub mobi
do
    if [ -d Issue"$VOLUME"_"$NUMBER"_"$fileType" ]; then
        rm -rf Issue"$VOLUME"_"$NUMBER"_"$fileType"
    fi
done

# Create folder for each file format
mkdir Issue"$VOLUME"_"$NUMBER"_{html,epub,mobi}

# Uncompress ZIP to HTML folder
unzip -j -q $FILE "hau$VOLUME.$NUMBER/*" -d "Issue"$VOLUME"_"$NUMBER"_html"
mkdir Issue"$VOLUME"_"$NUMBER"_html/images
mv Issue"$VOLUME"_"$NUMBER"_html/*.jpg Issue"$VOLUME"_"$NUMBER"_html/images/

# Remove link to stylesheet and correct ellipses in HTML files
for file in $(ls Issue"$VOLUME"_"$NUMBER"_html/*.html)
do
    sed -i 's:<link href="template.css" type="text/css" rel="stylesheet" />::g' $file
    sed -i 's/&#x2026;/\.\ \.\ \./g' $file
    sed -i 's/\.\ \.\ \.\ \./.\&nbsp;.\&nbsp;.\&nbsp;./g' $file
    sed -i 's/\.\ \.\ \./.\&nbsp;.\&nbsp;./g' $file
done

# Remove template.css file
# (Commented out. We want the file for now so we can compare to older version
# and see if anything has changed.)
#rm -f Issue"$VOLUME"_"$NUMBER"_html/template.css

# Check if latexmk, convert, and ebook-convert are available
command -v latexmk >/dev/null 2>&1 || { echo "I require TeXLive with latexmk but it's not installed.  Aborting." >&2; exit 1; }
command -v convert >/dev/null 2>&1 || { echo "I require ImageMagick with convert but it's not installed.  Aborting." >&2; exit 1; }
command -v ebook-convert >/dev/null 2>&1 || { echo "I require Calibre with ebook-convert but it's not installed.  Aborting." >&2; exit 1; }

# Create eBook Cover
sed s/%vol%/$VOLUME/ cover.tex | sed s/%no%/$NUMBER/ | sed s/%year%/$YEAR/ > cover_new.tex

latexmk -pdf cover_new.tex
latexmk -c cover_new.tex

convert cover_new.pdf cover_new.jpg

# Create eBook files
for file in $(ls Issue"$VOLUME"_"$NUMBER"_html/*.html)
do
    ebook-convert $file Issue"$VOLUME"_"$NUMBER"_epub/$(echo $file | sed 's/\(.*\)hau\(.*\).html/hau\2.epub/') \
    --chapter=/ --page-breaks-before=/ \
    --extra-css=eBookCSS.css \
    --cover=cover_new.jpg

    ebook-convert $file Issue"$VOLUME"_"$NUMBER"_mobi/$(echo $file | sed 's/\(.*\)hau\(.*\).html/hau\2.mobi/') \
    --chapter=/ --page-breaks-before=/ \
    --extra-css=eBookCSS.css \
    --cover=cover_new.jpg \
    --no-inline-toc
done

# Cleanup created cover_new files
rm -f cover_new.{tex,pdf,jpg}
