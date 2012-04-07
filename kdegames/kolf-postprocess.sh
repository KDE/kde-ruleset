#!/bin/bash

set -e

# Execute this script from the converted repository.

bindir="${RULESETDIR:?\$RULESETDIR must point to the kde-ruleset directory}/bin"
source "$bindir/filter-goodies"

git update-ref -d refs/backups/r467490/tags/v3.4.3
git update-ref -d refs/backups/r519761/tags/v3.5.2
git update-ref -d refs/backups/r591395/tags/v3.5.5

# why are those here at all? rules should have excluded them
git update-ref -d refs/workbranch/qdbus-api-changes
git update-ref -d refs/workbranch/kparts_urlargs_split
git update-ref -d refs/workbranch/kconfig_new
git update-ref -d refs/workbranch/kconfiggroup_port
git update-ref -d refs/workbranch/kde4_jobflags
git update-ref -d refs/workbranch/kde4_kconfig
git update-ref -d refs/workbranch/kaction-cleanup1
git update-ref -d refs/workbranch/kaction-cleanup2
git update-ref -d refs/workbranch/kaction-cleanup3
git update-ref -d refs/workbranch/systray-rewrite
git update-ref -d refs/workbranch/systray-rewrite-tng


echo 'parent-adder...'
$bindir/parent-adder $RULESETDIR/kdegames/kolf-parentmap

echo 'delete_fb_backups...'
delete_fb_backups

echo 'fix-tags...'
$bindir/fix-tags
delete_fb_backups

git filter-branch --tree-filter $RULESETDIR/kdegames/kolf-tree-filter --tag-name-filter cat -- --all
delete_fb_backups

#echo 'add revision tags for debugging...'
#add_revision_tags

git reflog expire --expire=now --all
git gc
