#!/bin/bash

initial_dir=$(pwd)

for dir in */; do
    if [ -d "$dir" ]; then
        echo -e "\n=== Pull de $dir ==="
        cd "$dir"
        
        if [ -d ".git" ]; then
            git pull
        else
            echo "Ce n'est pas un dépôt git"
        fi
        
        cd "$initial_dir"
    fi
done