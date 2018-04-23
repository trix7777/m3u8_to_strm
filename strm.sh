#!/bin/bash
LISTA="lista.m3u"
LINHA_INFO=0
echo "\033[0;31mM3U8 to strm - by Miguel Targa\033[0m"
IFS=$'\n'
(
  while read LINHA; do
    INFO=$(echo "$LINHA" | grep '^#EXTINF:')
    if [ "$LINHA_INFO" -eq 0 ] && [ -n "$INFO" ]; then
      LINHA_INFO=1
      PASTA=$(echo "$LINHA" | sed -E 's/.*group-title="([^"]+).*/\1/')
      TITULO=$(echo "$LINHA" | sed 's|.*,||')  
    fi
    if [ "$LINHA_INFO" -eq 1 ] && [ -z "$INFO" ]; then
      mkdir -p $PASTA
      printf "%s" "$LINHA" >> "$PASTA/$TITULO.strm"
      echo "Creating: $PASTA/$TITULO.strm"
      LINHA_INFO=0
   fi
 done < "$LISTA"
) 
echo "\033[0;31mDone!\033[0m"