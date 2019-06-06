#!/bin/bash

BOLD='\033[1m'
UND033RLIN033='\033[4m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --no-color)
    BOLD=''; UNDERLINE=''; RED=''; GREEN=''; NC=''
    shift
    ;;
esac
done

meta() {
  cat _posts/${1} | grep "^${2}:" | head -n1 \
    | sed -e "s/^${2}:\s*\(.*\)$/\1/" \
    | sed -e "s/^[ ]*//" | sed -e "s/[ ]*$//" \
    | sed -e "s/^[\"']//" | sed -e "s/[\"']$//"
}

isEpisode() {
  if [[ "$(meta "$1" "category")" = "podcast" ]] || [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-fki[0-9]{4}\.md$ ]]; then
    return 0
  fi

  return 1
}

contains() {
  if [[ $(cat "_posts/${1}" | grep "${2}") != "" ]]; then
    return 0
  fi
  return 1
}

status=0

for f in $(ls _posts); do
  if isEpisode "$f"; then
    echo -e "${BOLD}${UNDERLINE}${f}${NC}"

    episodeStatus=0

    # file name
    if ! [[ "$f" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-fki[0-9]{4}\.md$ ]]; then
      echo -e "[${RED}ERROR${NC}] File name should have the format: YYYY-MM-DD-fki0001.md"
      episodeStatus=1
    fi

    # echo -e "2018-08-08 21:00:00+02:00" | sed 's/^\([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\).*/\1/'

    # layout
    if [[ "$(meta "$f" "layout")" != "post" ]]; then
      echo -e "[${RED}ERROR${NC}] Should have the layout post"
      episodeStatus=1
    fi

    # category
    if [[ "$(meta "$f" "category")" != "podcast" ]]; then
      echo -e "[${RED}ERROR${NC} Should have the category podcast"
      episodeStatus=1
    fi

    # recording date
    recording_datetime=$(meta "$f" "recording_date")
    recording_date=$(echo $recording_datetime | sed 's/^\([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\).*/\1/')
    if [[ "$recording_datetime" = "" ]]; then
      echo -e "[${RED}ERROR${NC}] Should have a recording_date"
      episodeStatus=1

    elif ! [[ "$f" =~ ^$recording_date-fki[0-9]{4}\.md$ ]]; then
      echo -e "[${RED}ERROR${NC}] File name should include recording date: $recording_date"
    fi

    # file
    file_url="$(meta "$f" "file_url")"
    if [[ "$file_url" = "" ]]; then
      echo -e "[${RED}ERROR${NC}] file_url should not be empty"
      episodeStatus=1
    else
      if [[ "$(curl -sSI $file_url | grep '200 OK')" = "" ]]; then
        echo -e "[${RED}ERROR${NC}] File url is unreachable"
        episodeStatus=1
      fi

      rsize="$(curl -sSI $file_url | grep '^Content-Length: ' | sed 's/^Content-Length: \([0-9]*\).*/\1/')"
      msize="$(meta "$f" "file_size")"

      if [[ "$msize" != "$rsize" ]]; then
        echo -e "[${RED}ERROR${NC}] File size is wrong (should be '$rsize')"
        episodeStatus=1
      fi
    fi

    file_duration=$(meta "$f" "file_duration")
    if [[ "$file_duration" = "" ]] || [[ "$file_duration" = "00:00:00" ]]; then
      echo -e "[${RED}ERROR${NC}] file_duration should not be empty"
      episodeStatus=1
    fi

    file_size=$(meta "$f" "file_size")
    if [[ "$file_size" = "" ]] || [[ "$file_size" = "0" ]]; then
      echo -e "[${RED}ERROR${NC}] file_size should not be empty"
      episodeStatus=1
    fi

    # title
    title=$(meta "$f" "title")
    if [[ "$title" = "" ]]; then
      echo -e "[${RED}ERROR${NC}] Title should not be empty"
      episodeStatus=1
    elif ! [[ "$title" =~ ^FKI[0-9]{4} ]]; then
      echo -e "[${RED}ERROR${NC}] Title should have the format: FKI0000 Title"
      episodeStatus=1
    elif [[ "$(echo $title | grep TBD)" != "" ]]; then
      echo -e "[${RED}ERROR${NC}] Title should not include TBD"
      episodeStatus=1
    fi

    # permalink: /:title
    permalink=$(meta "$f" "permalink")
    if [[ "$permalink" != "/:title" ]]; then
      echo -e "[${RED}ERROR${NC}] permalink should be /:title"
      episodeStatus=1
    fi

    if contains "$f" "^## " || contains "$f" "^# "; then
      echo -e "[${RED}ERROR${NC}] description should not contain h1 or h2 headings"
      episodeStatus=1
    fi

    if [[ "$episodeStatus" = 0 ]]; then
      echo -e "[${GREEN}OK${NC}] No errors"
    else
      status=1
    fi

    echo -e ""
  fi
done

exit $status
