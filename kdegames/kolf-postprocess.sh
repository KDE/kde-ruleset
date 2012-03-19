#!/bin/bash

set -e

if test ! -d kde-ruleset
then
	echo execute this in a directory with subdirectories kde-ruleset
	exit 2
fi

which fromdos >/dev/null || {
	echo kolf-postprocess.sh: please install package tofrodos, we need fromdos
	exit 2
}

export RULESETDIR=`pwd`/kde-ruleset
export REPO=kolf

if test ! -d $REPO -a ! -d $REPO.org
then
	echo repository $REPO or $REPO.org or $REPO.org not found
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
$bindir/parent-adder $RULESETDIR/kdegames/$REPO-parentmap

echo 'delete_fb_backups...'
delete_fb_backups

# those are all cases where svn2git returns a first
# commit for a new branch which holds only the changed
# files so git thinks all others have been deleted.
# the second argument is the master branch from which
# to merge the missing files.
fill_from 190314 KDE/3.1 v3.1.0 v3.1.1 v3.1.2 v3.1.3 v3.1.4 v3.1.5
fill_from 280126 KDE/3.2 v3.2.1 v3.2.2 v3.2.3
fill_from 335035 KDE/3.3 v3.3.0 v3.3.1 v3.3.2
fill_from 387945 KDE/3.4

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
