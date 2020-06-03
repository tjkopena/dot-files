#!/usr/bin/env bash
# Spawn a terminal in the current working directory of the active window if it is a terminal
# Inspired by https://www.reddit.com/r/swaywm/comments/fp58p1/get_the_current_working_directory_of_a_window_in/

name=$( swaymsg -t get_tree | jq '.. | (.nodes? // empty)[] | select(.focused==true).name? // empty')
name=${name%\"}
name=${name#\"}

nwd=
if [[ "$name" = "joe@alice: "* ]]
then
    name=${name#"joe@alice: "}
    if [[ "$name" = "~"* ]]
    then
        name=$HOME${name#"~"}
    fi

    if [ -d "$name" ]
    then
        nwd=${name}
    fi
fi

if [ -n "$nwd" ]; then
  gnome-terminal --working-directory="$nwd" &
  disown
else
  gnome-terminal &
  disown
fi
