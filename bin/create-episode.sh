#!/bin/bash

file_path="$1"

if [[ "$file_path" = "" ]]; then
  echo "Usage: bin/create-episode.sh <file-path>"
  exit 1
fi

dateDefault=$(date +%Y-%m-%d)
read -p "Recording date [$dateDefault] " recordingDate
recordingDate=${recordingDate:-"$dateDefault"}

dateDefault=$(date -v +1d +%Y-%m-%d)
read -p "Publish date   [$dateDefault] " publishDate
publishDate=${publishDate:-"$dateDefault"}

slug=$(echo "$file_path" | sed 's/^.*\/\([^/]*\)\.mp3$/\1/' | sed 's/\///g')
slugUp=$(echo "$slug" | tr '[:lower:]' '[:upper:]')
size=$(du -k "$file_path" | cut -f1)
len=$(ffmpeg -i $file_path 2>&1 | grep Duration | sed 's/.*Duration: \([^.]*\).*/\1/')

cat bin/template/episode.md \
  | sed "s/{PUBLISH_DATE}/$publishDate/" \
  | sed "s/{RECORDING_DATE}/$recordingDate/" \
  | sed "s/{SLUG}/$slug/" \
  | sed "s/{SLUG_UPPER}/$slugUp/" \
  | sed "s/{SIZE}/$size/" \
  | sed "s/{LENGTH}/$len/" \
  > "_posts/${publishDate}-${slug}.md"
