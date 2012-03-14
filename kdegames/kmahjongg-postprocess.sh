#!/bin/bash

set -e

if test ! -d kde-ruleset
then
	echo execute this in a directory with subdirectories kde-ruleset
	exit 2
fi

export RULESETDIR=`pwd`/kde-ruleset
export REPO=kmahjongg

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

echo 'parent-adder...'
$bindir/parent-adder $RULESETDIR/kdegames/$REPO-parentmap

echo 'delete_fb_backups...'
delete_fb_backups

# those are all cases where svn2git returns a first
# commit for a new branch which holds only the changed
# files so git thinks all others have been deleted.
# the second argument is the master branch from which
# to merge the missing files.
fill_branch KDE/1.1 16462
fill_branch KDE/2.0 67702
fill_branch KDE/2.1 83372
fill_branch KDE/2.2 109165
fill_branch KDE/3.0 144485
fill_branch KDE/3.1 189718
fill_branch KDE/3.2 279832
fill_branch KDE/3.3 334652
fill_branch KDE/3.4 401169
fill_branch v1.1.1 16462
fill_branch v1.1.2 16462
fill_branch v2.0.1 67702
fill_branch v2.1.1 83372
fill_branch v2.2.1 109165
fill_branch v2.2.2 109165
fill_branch v3.0.2 144485
fill_branch v3.0.3 144485
fill_branch v3.0.4 144485
fill_branch v3.0.5 144485
fill_branch v3.0.5A 144485
fill_branch v3.1.0 189718
fill_branch v3.1.1 189718
fill_branch v3.1.2 189718
fill_branch v3.1.3 189718
fill_branch v3.1.4 189718
fill_branch v3.1.5 189718
fill_branch v3.2.1 279832
fill_branch v3.2.2 279832
fill_branch v3.2.3 279832
fill_branch v3.3.1 334652
fill_branch v3.3.2 334652

echo 'delete_fb_backups...'
delete_fb_backups

echo 'fix-tags...'
$bindir/fix-tags
delete_fb_backups

change_cvs2svn_author
delete_fb_backups

# echo 'add revision tags for debugging...'
# add_revision_tags

git reflog expire --expire=now --all
git gc
