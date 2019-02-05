#!/bin/bash

file_path="$1"

if [[ "$file_path" = "" ]]; then
  echo "Usage: bin/create-episode.sh <file-path>"
  exit 1
fi

recordingDate="$2"
if [[ "$recordingDate" = "" ]]; then
  dateDefault=$(date +%Y-%m-%d)
  read -p "Recording date [$dateDefault] " recordingDate
  recordingDate=${recordingDate:-"$dateDefault"}
fi

publishDate="$2"
if [[ "$publishDate" = "" ]]; then
  dateDefault=$(date -v +1d +%Y-%m-%d)
  read -p "Publish date   [$dateDefault] " publishDate
  publishDate=${publishDate:-"$dateDefault"}
fi

slug=$(echo "$file_path" | sed 's/^.*\/\([^/]*\)\.mp3$/\1/' | sed 's/\///g')
slugUp=$(echo "$slug" | tr '[:lower:]' '[:upper:]')
size=$(du -k "$file_path" | cut -f1)
len=$(ffmpeg -i $file_path 2>&1 | grep Duration | sed 's/.*Duration: \([^.]*\).*/\1/')

postFile="_posts/${publishDate}-${slug}.md"
chapterFile="$(echo $file_path | sed 's/\.mp3$/.chapters.txt/')"

# read -r -d '' TEMPLATE << EOS

FILE="tmp.md"
cat > $FILE <<- EOS
---
layout:         post
category:       podcast
title:          "{{ SLUG_UPPER }} TBD"
date:           {{ PUBLISH_DATE }} 12:00:00+02:00
recording_date: {{ RECORDING_DATE }} 21:00:00+02:00
file_url:       "https://s3.eu-central-1.amazonaws.com/feinkost-intenet/{{ SLUG }}.mp3"
file_duration:  "{{ DURATION }}"
file_size:      {{ SIZE }}
permalink:      /:title
team:
- josa
- robert
- stefan
- thomas
---

### Themen

EOS


cat $FILE \
  | sed "s/{{ PUBLISH_DATE }}/$publishDate/" \
  | sed "s/{{ RECORDING_DATE }}/$recordingDate/" \
  | sed "s/{{ SLUG }}/$slug/" \
  | sed "s/{{ SLUG_UPPER }}/$slugUp/" \
  | sed "s/{{ SIZE }}/$size/" \
  | sed "s/{{ DURATION }}/$len/" \
  > "$postFile"

rm $FILE

if [ -f "$chapterFile" ]; then
  cat  $chapterFile | sed 's/^[0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9][0-9] //' | grep -vi '\(intro\|outro\)' | sed 's/^/* /' >> "$postFile"
fi


cat $postFile
