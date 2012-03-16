#!/bin/bash

# this script is to be started in the parent directory of kde-ruleset, svn2git
# and svn

if test ! -d kde-ruleset -o ! -d svn
then
	echo execute this in the directory with subdirectories kde-ruleset and svn
	exit 2
fi

rm -rf libkmahjongg.prev libkmahjongg.org
if test -d libkmahjongg
then
	mv libkmahjongg libkmahjongg.prev
	mv log-libkmahjongg gitlog-libkmahjongg svn2gitlog-libkmahjongg libkmahjongg.prev 2>/dev/null
fi

set -e

svn2git/svn-all-fast-export --resume-from=610847 \
	--identity-map=kde-ruleset/account-map --add-metadata \
	--rules=kde-ruleset/kdegames/libkmahjongg-rules \
	svn >svn2gitlog-libkmahjongg 2>&1

# make a copy of the result so we can repeatedly test libkmahjongg-postprocess.sh on it
cp -a libkmahjongg libkmahjongg.org

exec kde-ruleset/kdegames/libkmahjongg-postprocess.sh
