#!/usr/bin/env bash

json_file_with_title="book.json"
title_font="Courier-10-Pitch"

font_is_on_system () {
    convert -list font | grep -q $title_font
}

get_title_from_json () {
    grep -Po '"title":\s"\K[^"]+' $json_file_with_title
}

put_padding_into_image () {
    local top_border="0"
    local left_border="20"
    echo "-gravity northwest -splice ${left_border}x${top_border}"
}

if [ ! -f $json_file_with_title ]
then
    echo "The file $json_file_with_title was not found"
    exit 1
fi

if [ $(get_title_from_json | wc -c) -eq 0 ]
then
    echo "The title key was not found into $json_file_with_title file"
    exit 1
fi
    
if ! $(font_is_on_system)
then
    echo "The font $title_font needs to be installed on the system"
    exit 1
fi

convert -font $title_font \
    -gravity west \
    -background "#0000" \
    -fill black \
    -size 590x300 \
    caption:"$(get_title_from_json)" \
    $(put_padding_into_image) \
    ./images/clean-cover.png \
    +swap \
    -gravity northwest \
    -composite ./images/cover.png

