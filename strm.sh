#!/bin/bash
LISTA="lista.m3u"
LINHA_INFO=0
LINHA_URL=0
IFS=$'\n'
(
  while read LINHA; do
    INFO=$(echo "$LINHA" | grep '^#EXTINF:')
    if [ "$LINHA_INFO" -eq 0 ] && [ "$LINHA_URL" -eq 0 ] && [ -n "$INFO" ]; then
      LINHA_INFO=1
      LINHA_URL=0
      TITULO=$(echo "$LINHA" | sed 's|.*,||')  
    fi
    if [ "$LINHA_INFO" -eq 1 ] && [ "$LINHA_URL" -eq 0 ] && [ -z "$INFO" ]; then
      echo "$LINHA" > "$TITULO.strm"
      LINHA_INFO=0
      LINHA_URL=0
   fi
 done < "$LISTA"
) 