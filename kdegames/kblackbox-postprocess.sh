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

# unannotated tag cannot be pushed to KDE
#git tag -d backups/master@473660

echo 'parent-adder...'
$bindir/parent-adder $RULESETDIR/kdegames/kblackbox-parentmap

echo 'delete_fb_backups...'
delete_fb_backups

# those are all cases where svn2git returns a first
# commit for a new branch which holds only the changed
# files so git thinks all others have been deleted.
# the second argument is the master branch from which
# to merge the missing files.
fill_from 16472 KDE/1.1 v1.1.1 v1.1.2
fill_from 67702 KDE/2.0 v2.0.1
fill_from 83708 KDE/2.1 v2.1.0 v2.1.1
fill_from 109165 KDE/2.2 v2.2.1 v2.2.2
fill_from 144295 KDE/3.0 v3.0.1 v3.0.2 v3.0.3 v3.0.4 v3.0.5 v3.0.5A
fill_from 189718 KDE/3.1 v3.1.0 v3.1.1 v3.1.2 v3.1.3 v3.1.4 v3.1.5
fill_from 279832 KDE/3.2 v3.2.1 v3.2.2 v3.2.3
fill_from 334652 KDE/3.3 v3.3.0 v3.3.1 v3.3.2
fill_from 389826 KDE/3.4

echo 'delete_fb_backups...'
delete_fb_backups

echo 'fix-tags...'
$bindir/fix-tags
delete_fb_backups

#echo 'add revision tags for debugging...'
#add_revision_tags

git reflog expire --expire=now --all
git gc
