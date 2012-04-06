#!/bin/bash

set -e

# Execute this script from the converted repository.

bindir="${RULESETDIR:?\$RULESETDIR must point to the kde-ruleset directory}/bin"
source "$bindir/filter-goodies"

echo 'parent-adder...'
$bindir/parent-adder $RULESETDIR/kdegames/kbounce-parentmap

echo 'delete_fb_backups...'
delete_fb_backups

echo 'fix-tags...'
$bindir/fix-tags
delete_fb_backups

change_cvs2svn_author
delete_fb_backups

#echo 'add revision tags for debugging...'
#add_revision_tags

git reflog expire --expire=now --all
#git gc
