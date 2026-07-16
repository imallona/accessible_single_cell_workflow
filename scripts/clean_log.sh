#!/bin/sh
# Turns a quarto render or preview stream on stdin into a screen-reader-friendly
# plain-text stream on stdout. Removes ANSI escapes, collapses carriage-return
# progress redraws to their final state, and drops the progress-bar lines that
# redraw in place (the "|====| NN%" bars and the RcppProgress "0% ... 100%"
# ruler and "****" fill). Keeps the N/NNN chunk counters and every message and
# warning. sed -u and grep --line-buffered keep it streaming line by line, so a
# live preview reads out messages as they arrive instead of in delayed blocks.
sed -u -r 's/\x1b\[[0-9;?]*[a-zA-Z]//g' \
  | sed -u -r 's/.*\r//' \
  | sed -u -r 's/[[:space:]]+$//' \
  | grep -a --line-buffered -vE '^ *\|[=| ]*[0-9]{1,3}%$' \
  | grep -a --line-buffered -vE '^ *0%[0-9% ]*100%$' \
  | grep -a --line-buffered -vE '^\[[-|]+$' \
  | grep -a --line-buffered -vE '^\*+\|?$'
