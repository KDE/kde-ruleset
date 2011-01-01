#!/bin/sh
# This script merges two Krusader repositories (krusader_sf and krusader_kde) into one.

rm -rf krusader
rm -rf krusader_temp
git clone krusader_sf krusader_temp
cd krusader_temp
git remote add -f krusader_kde ../krusader_kde
git branch kde3 origin/kde3
echo "First, rewinding head to replay your work on top of it..."
git rebase --committer-date-is-author-date --quiet master krusader_kde/master
git branch -d master
git checkout -b master
git remote rm origin
echo "Fixing line endings:"
git filter-branch --tag-name-filter cat --tree-filter 'find . -path "./.git" -prune -o -name "*.jpg" -prune -o -name "*.png" -prune -o -name "*" -exec dos2unix -q "{}" \;' HEAD
echo "Removing .cvsignore files:"
git filter-branch -f --tag-name-filter cat --tree-filter 'find . -name ".cvsignore" -exec rm "{}" \;' -- --all
echo "Removing .gmo files:"
git filter-branch -f --tag-name-filter cat --tree-filter 'find . -name "*.gmo" -exec rm "{}" \;' kde3
echo "Removing .moc.cpp files:"
git filter-branch -f --tag-name-filter cat --tree-filter 'find . -name "*.moc.cpp" -exec rm "{}" \;' kde3
echo "Adding additional parent:"
echo `git rev-list HEAD | tail -1` `git rev-list -n 1 --first-parent --before=2007-05-12 kde3` > parentmap
git filter-branch -f --tag-name-filter cat --parent-filter "$(../../../bin/add-parents parentmap)" master
rm parentmap
cd ..
git clone krusader_temp krusader
rm -rf krusader_temp
cd krusader
git branch kde3 origin/kde3
git remote rm origin
git gc --aggressive
