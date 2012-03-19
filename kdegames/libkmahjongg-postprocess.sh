#!/bin/bash

set -e

if test ! -d kde-ruleset
then
	echo execute this in a directory with subdirectories kde-ruleset
	exit 2
fi

export RULESETDIR=`pwd`/kde-ruleset
export REPO=libkmahjongg

if test ! -d $REPO -a ! -d $REPO.org
then
	echo repository $REPO or $REPO.org not found
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

echo 'parent-adder...'
$bindir/parent-adder $RULESETDIR/kdegames/$REPO-parentmap

echo 'delete_fb_backups...'
delete_fb_backups
