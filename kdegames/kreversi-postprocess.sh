#!/bin/bash

set -e

if test ! -d kde-ruleset
then
	echo execute this in a directory with subdirectories kde-ruleset
	exit 2
fi

export RULESETDIR=`pwd`/kde-ruleset
export REPO=kreversi

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

# those are all cases where svn2git returns a first
# commit for a new branch which holds only the changed
# files so git thinks all others have been deleted.
# the second argument is the master branch from which
# to merge the missing files.
fill_branch KDE/1.1 16310
fill_branch KDE/2.0 67702
fill_branch KDE/2.1 75098
fill_branch KDE/2.2 109165
fill_branch KDE/3.0 145047
fill_branch KDE/3.1 189718
fill_branch KDE/3.2 279832
fill_branch KDE/3.3 335035
fill_branch KDE/3.4 387945
fill_branch v1.1.1 16310
fill_branch v1.1.2 16310
fill_branch v2.0.1 67702
#fill_branch v2.1.0 83708
fill_branch v2.1.1 83708
fill_branch v2.2.1 109165
fill_branch v2.2.2 109165
fill_branch v3.0.1 145047
fill_branch v3.0.2 145047
fill_branch v3.0.3 145047
fill_branch v3.0.4 145047
fill_branch v3.0.5 145047
fill_branch v3.0.5A 145047
fill_branch v3.1.0 189718
fill_branch v3.1.1 189718
fill_branch v3.1.2 189718
fill_branch v3.1.3 189718
fill_branch v3.1.4 189718
fill_branch v3.1.5 189718
fill_branch v3.2.1 279832
fill_branch v3.2.2 279832
fill_branch v3.2.3 279832
fill_branch v3.3.0 335035
fill_branch v3.3.1 335035
fill_branch v3.3.2 335035

echo 'delete_fb_backups...'
delete_fb_backups

echo 'fix-tags...'
$bindir/fix-tags
delete_fb_backups

#echo 'add revision tags for debugging...'
#add_revision_tags

git reflog expire --expire=now --all
git gc
