#!/bin/bash

# Sauvegarde le répertoire initial
initial_dir=$(pwd)

# Pour chaque dossier dans le répertoire courant
for dir in */; do
    if [ -d "$dir" ]; then
        echo -e "\n=== Vérification de $dir ==="
        cd "$dir"
        
        # Vérifie si c'est un dépôt git
        if [ -d ".git" ]; then
            git status
        else
            echo "Ce n'est pas un dépôt git"
        fi
        
        # Retourne au répertoire parent
        cd "$initial_dir"
    fi
done