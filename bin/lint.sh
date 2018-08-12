#1/bin/bash

BOLD='\033[1m'
UNDERLINE='\033[4m'
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
  # echo "$(cat _posts/$1 | grep $2 | sed "s/$2:[ ]*[\"']?\(.*\)[\"']?/\1/")"
  echo "$(cat _posts/$1 | grep "^${2}:" | sed "s/$2:[ ]*[\"']*\([^\"'\n]*\)[\"']*/\1/")"
}

isEpisode() {
  if [[ "$(meta "$1" "category")" = "podcast" ]] || [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-fki[0-9]{4}\.md$ ]]; then
    return 0
  fi

  return 1
}

status=0

for f in $(ls _posts); do
  if isEpisode "$f"; then
    echo "${BOLD}${UNDERLINE}${f}${NC}"

    episodeStatus=0

    # file name
    if ! [[ "$f" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-fki[0-9]{4}\.md$ ]]; then
      echo "[${RED}ERROR${NC}] File name should have the format: YYYY-MM-DD-fki0001.md"
      episodeStatus=1
    fi

    # echo "2018-08-08 21:00:00+02:00" | sed 's/^\([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\).*/\1/'

    # category
    if [[ "$(meta "$f" "layout")" != "post" ]]; then
      echo "[${RED}ERROR${NC}] Should have the layout post"
      episodeStatus=1
    fi

    # category
    if [[ "$(meta "$f" "category")" != "podcast" ]]; then
      echo "[${RED}ERROR${NC}] Should have the category podcast"
      episodeStatus=1
    fi

    # recording date
    recording_datetime=$(meta "$f" "recording_date")
    recording_date=$(echo $recording_datetime | sed 's/^\([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\).*/\1/')
    if [[ "$recording_datetime" = "" ]]; then
      echo "[${RED}ERROR${NC}] Should have a recording_date"
      episodeStatus=1

    elif ! [[ "$f" =~ ^$recording_date-fki[0-9]{4}\.md$ ]]; then
      echo "[${RED}ERROR${NC}] File name should include recording date: $recording_date"
    fi

    # file
    file_url="$(meta "$f" "file_url")"
    # echo "$file_url"
    if [[ "$file_url" = "" ]]; then
      echo "[${RED}ERROR${NC}] file_url should not be empty"
      episodeStatus=1
    elif [[ "$(curl -sSI $file_url | grep '200 OK')" = "" ]]; then
      echo "[${RED}ERROR${NC}] File url is unreachable"
    fi

    file_duration=$(meta "$f" "file_duration")
    if [[ "$file_duration" = "" ]] || [[ "$file_duration" = "00:00:00" ]]; then
      echo "[${RED}ERROR${NC}] file_duration should not be empty"
      episodeStatus=1
    fi

    file_size=$(meta "$f" "file_size")
    if [[ "$file_size" = "" ]] || [[ "$file_size" = "0" ]]; then
      echo "[${RED}ERROR${NC}] file_size should not be empty"
      episodeStatus=1
    fi

    # title
    title=$(meta "$f" "title")
    if [[ "$title" = "" ]]; then
      echo "[${RED}ERROR${NC}] Title should not be empty"
      episodeStatus=1
    elif ! [[ "$title" =~ ^FKI[0-9]{4}  ]]; then
      echo "[${RED}ERROR${NC}] Title should have the format: FKI0000 Title"
      episodeStatus=1
    elif [[ "$(echo $title | grep TBD)" != "" ]]; then
      echo "[${RED}ERROR${NC}] Title should not include TBD"
      episodeStatus=1
    fi

    # permalink: /:title
    permalink=$(meta "$f" "permalink")
    if [[ "$permalink" != "/:title" ]]; then
      echo "[${RED}ERROR${NC}] permalink should be /:title"
      episodeStatus=1
    fi

    if [[ "$episodeStatus" = 0 ]]; then
      echo "[${GREEN}OK${NC}] No errors"
    else
      status=1
    fi


    echo ""
  fi
done

exit $status
