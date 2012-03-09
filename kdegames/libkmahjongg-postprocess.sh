#!/bin/bash

set -e

if test ! -d kde-ruleset
then
	echo execute this in a directory with subdirectories kde-ruleset
	exit 2
fi

export RULESETDIR=`pwd`/kde-ruleset

# if we have a copy of what svn2git created, start over with that copy

if test -d libkmahjongg.org
then
	rm -rf libkmahjongg
	cp -a libkmahjongg.org libkmahjongg
fi

cd libkmahjongg

bindir="${RULESETDIR:?\$RULESETDIR must point to the kde-ruleset directory}/bin"
source "$bindir/filter-goodies"

echo 'filter-branch...'
tempdir="$(calc_tempdir libkmahjongg-filter)"

# r634260 contains only the changed files in that branch
# This makes the git revision appear as deleting all the rest of the tree.
# Here we filter all revisions in the branch (both of them!)
# to contain the rest of the files, taken from the master revision right before branching.

# this code initially copied from kdegraphics/okular, but did not work for me.
# I had to replace master.. by ${prevmaster}..

prevmaster=$(echo 629421 | $bindir/translateRevlist.py)

git filter-branch -f -d "$tempdir" \
    --tree-filter "git read-tree $prevmaster" \
    ${prevmaster}..workbranch/kconfiggroup_port

echo 'delete_fb_backups...'
delete_fb_backups

echo 'parent-adder...'
$bindir/parent-adder $RULESETDIR/kdegames/libkmahjongg-parentmap

echo 'delete_fb_backups...'
delete_fb_backups

echo 'fix-tags...'
$bindir/fix-tags
