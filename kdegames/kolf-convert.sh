#!/bin/bash

# this script is to be started in the parent directory of kde-ruleset, svn2git
# and svn

if test ! -d kde-ruleset -o ! -d svn
then
	echo execute this in the directory with subdirectories kde-ruleset and svn
	exit 2
fi

if test -d kolf.org
then
	rm -rf kolf.prev kolf.org.prev
	mv kolf.org kolf.org.prev
	mv log-kolf gitlog-kolf svn2gitlog-kolf kolf.org.prev 2>/dev/null
fi

set -e

rm -rf kolf
svn2git/svn-all-fast-export \
	--identity-map=kde-ruleset/account-map --add-metadata \
	--rules=kde-ruleset/kdegames/kolf-rules \
	svn >svn2gitlog-kolf 2>&1

# make a copy of the result so we can repeatedly test kolf-postprocess.sh on it
cp -a kolf kolf.org

exec kde-ruleset/kdegames/kolf-postprocess.sh
