#!/bin/bash

# this script is to be started in the parent directory of kde-ruleset, svn2git
# and svn

if test ! -d kde-ruleset -o ! -d svn
then
	echo execute this in the directory with subdirectories kde-ruleset and svn
	exit 2
fi

if test -d katomic.org
then
	rm -rf katomic.prev katomic.org.prev
	mv katomic.org katomic.org.prev
	mv log-katomic gitlog-katomic svn2gitlog-katomic katomic.org.prev 2>/dev/null
fi

set -e

rm -rf katomic
svn2git/svn-all-fast-export \
	--identity-map=kde-ruleset/account-map --add-metadata \
	--rules=kde-ruleset/kdegames/katomic-rules \
	svn >svn2gitlog-katomic 2>&1

# make a copy of the result so we can repeatedly test katomic-postprocess.sh on it
cp -a katomic katomic.org

exec kde-ruleset/kdegames/katomic-postprocess.sh
