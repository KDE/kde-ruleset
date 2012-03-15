#!/bin/bash

# this script is to be started in the parent directory of kde-ruleset, svn2git
# and kde_svn

if test ! -d kde-ruleset -o ! -d kde_svn
then
	echo execute this in the directory with subdirectories kde-ruleset and kde_svn
	exit 2
fi

if test -d kreversi.org
then
	rm -rf kreversi.prev kreversi.org.prev
	mv kreversi.org kreversi.org.prev
	mv log-kreversi gitlog-kreversi svn2gitlog-kreversi kreversi.org.prev 2>/dev/null
fi

set -e

rm -rf kreversi
svn2git/svn-all-fast-export \
	--identity-map=kde-ruleset/account-map --add-metadata \
	--rules=kde-ruleset/kdegames/kreversi-rules \
	kde_svn >svn2gitlog-kreversi 2>&1

# make a copy of the result so we can repeatedly test kreversi-postprocess.sh on it
cp -a kreversi kreversi.org

exec kde-ruleset/kdegames/kreversi-postprocess.sh
