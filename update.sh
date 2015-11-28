#!/bin/bash

echo "Updating HOME dir"

echo "== PUBLIC SCRIPTS =="
cd dotfiles_public
for i in *; do 
    echo "Overwriting $i"
    rm -f "$HOME/.$i"
    ln -s "`pwd`/$i" "$HOME/.$i"
done;
