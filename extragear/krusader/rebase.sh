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
git filter-branch -f --tag-name-filter cat --tree-filter 'find . -name "*.gmo" -exec rm "{}" \;' -- --all
echo "Removing .moc.cpp files:"
git filter-branch -f --tag-name-filter cat --tree-filter 'find . -name "*.moc.cpp" -exec rm "{}" \;' -- --all
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
GIT_COMMITTER_DATE="2004-07-21 11:24:57 +0000" GIT_COMMITTER_NAME="Shie Erlich" GIT_COMMITTER_EMAIL="erlich@users.sourceforge.net" git tag -a -m "Tagging krusader-1.40.0" v1.40.0 `git rev-list -n 1 --before=2004-07-21 master`
GIT_COMMITTER_DATE="2004-10-16 21:00:44 +0000" GIT_COMMITTER_NAME="Dirk Eschler" GIT_COMMITTER_EMAIL="eschler@gmail.com" git tag -a -m "Tagging krusader-1.50.0-beta1" v1.50.0-beta1 `git rev-list -n 1 --before=2004-10-17 master`
GIT_COMMITTER_DATE="2004-10-31 12:14:42 +0000" GIT_COMMITTER_NAME="Shie Erlich" GIT_COMMITTER_EMAIL="erlich@users.sourceforge.net" git tag -a -m "Tagging krusader-1.50.0" v1.50.0 `git rev-list --after=2004-10-30 master | tail -2 | head -1`
GIT_COMMITTER_DATE="2005-03-03 08:36:58 +0000" GIT_COMMITTER_NAME="Shie Erlich" GIT_COMMITTER_EMAIL="erlich@users.sourceforge.net" git tag -a -m "Tagging krusader-1.60.0-beta1" v1.60.0-beta1 `git rev-list -n 2 --before=2005-03-04 master | tail -1`
GIT_COMMITTER_DATE="2005-04-09 12:20:00 +0000" GIT_COMMITTER_NAME="Dirk Eschler" GIT_COMMITTER_EMAIL="eschler@gmail.com" git tag -a -m "Tagging krusader-1.60.0" v1.60.0 `git rev-list -n 1 --before=2005-04-10 master`
GIT_COMMITTER_DATE="2008-03-14 18:23:41 +0000" GIT_COMMITTER_NAME="Frank Schoolmeesters" GIT_COMMITTER_EMAIL="codeknight@users.sourceforge.net" git tag -a -m "Tagging krusader-1.90.0" v1.90.0 `git rev-list -n 1 --before=2008-03-15 kde3`
GIT_COMMITTER_DATE="2009-10-27 21:07:23 +0000" GIT_COMMITTER_NAME="Dirk Eschler" GIT_COMMITTER_EMAIL="eschler@gmail.com" git tag -a -m "Tagging krusader-2.1.0-beta1" v2.1.0-beta1 `git rev-list -n 1 --before=2009-10-28  master`
GIT_COMMITTER_DATE="2010-04-30 16:35:25 +0000" GIT_COMMITTER_NAME="Dirk Eschler" GIT_COMMITTER_EMAIL="eschler@gmail.com" git tag -a -m "Tagging krusader-2.2.0-beta1" v2.2.0-beta1 `git rev-list -n 1 --before=2010-05-01  master`
GIT_COMMITTER_DATE="2010-12-25 19:15:17 +0000" GIT_COMMITTER_NAME="Dirk Eschler" GIT_COMMITTER_EMAIL="eschler@gmail.com" git tag -a -m "Tagging krusader-2.3.0-beta1" v2.3.0-beta1 `git rev-list -n 1 --before=2010-12-26  master`
git gc --aggressive
