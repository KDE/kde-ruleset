#!/bin/bash

# this script is to be started in the parent directory of kde-ruleset, svn2git
# and svn

if test ! -d kde-ruleset -o ! -d svn
then
	echo execute this in the directory with subdirectories kde-ruleset and svn
	exit 2
fi

if test -d kblackbox.org
then
	rm -rf kblackbox.prev kblackbox.org.prev
	mv kblackbox.org kblackbox.org.prev
	mv log-kblackbox gitlog-kblackbox svn2gitlog-kblackbox kblackbox.org.prev 2>/dev/null
fi

set -e

rm -rf kblackbox
svn2git/svn-all-fast-export \
	--identity-map=kde-ruleset/account-map --add-metadata \
	--rules=kde-ruleset/kdegames/kblackbox-rules \
	svn >svn2gitlog-kblackbox 2>&1

# make a copy of the result so we can repeatedly test kblackbox-postprocess.sh on it
cp -a kblackbox kblackbox.org

exec kde-ruleset/kdegames/kblackbox-postprocess.sh
