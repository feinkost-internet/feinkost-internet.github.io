#!/bin/bash

docker run --rm \
  -p 4000:4000 \
  --volume=$PWD:/srv/jekyll \
  -it jekyll/jekyll:3.5 \
  jekyll serve
