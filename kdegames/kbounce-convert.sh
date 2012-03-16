#!/bin/bash

# this script is to be started in the parent directory of kde-ruleset, svn2git
# and svn

if test ! -d kde-ruleset -o ! -d svn
then
	echo execute this in the directory with subdirectories kde-ruleset and svn
	exit 2
fi

if test -d kbounce.org
then
	rm -rf kbounce.prev kbounce.org.prev
	mv kbounce.org kbounce.org.prev
	mv log-kbounce gitlog-kbounce svn2gitlog-kbounce kbounce.org.prev 2>/dev/null
fi

set -e

rm -rf kbounce
svn2git/svn-all-fast-export \
	--identity-map=kde-ruleset/account-map --add-metadata \
	--rules=kde-ruleset/kdegames/kbounce-rules \
	svn >svn2gitlog-kbounce 2>&1

# make a copy of the result so we can repeatedly test kbounce-postprocess.sh on it
cp -a kbounce kbounce.org

exec kde-ruleset/kdegames/kbounce-postprocess.sh
