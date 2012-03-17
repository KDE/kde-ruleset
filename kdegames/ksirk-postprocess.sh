#!/bin/bash

set -e

if test ! -d kde-ruleset
then
	echo execute this in a directory with subdirectories kde-ruleset
	exit 2
fi

export RULESETDIR=`pwd`/kde-ruleset
export REPO=ksirk

if test ! -d $REPO
then
	echo repository $REPO not found
	exit 1
fi

# if we have a copy of what svn2git created, start over with that copy
if test -d $REPO.org
then
	rm -rf $REPO
	cp -a $REPO.org $REPO
fi

cd $REPO

bindir="${RULESETDIR:?\$RULESETDIR must point to the kde-ruleset directory}/bin"
source "$bindir/filter-goodies"

git update-ref -d refs/backups/r467490/tags/v3.4.3
git update-ref -d refs/backups/r519761/tags/v3.5.2
git update-ref -d refs/backups/r591395/tags/v3.5.5
git update-ref -d refs/tags/backups/master@798832
git update-ref -d refs/tags/backups/master@804025

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
$bindir/parent-adder $RULESETDIR/kdegames/$REPO-parentmap

echo 'delete_fb_backups...'
delete_fb_backups

#echo 'add revision tags for debugging...'
#add_revision_tags

git reflog expire --expire=now --all
git gc
