#!/bin/bash

# this script is to be started in the parent directory of kde-ruleset, svn2git
# and svn

if test ! -d kde-ruleset -o ! -d svn
then
	echo execute this in the directory with subdirectories kde-ruleset and svn
	exit 2
fi

if test -d kspaceduel.org
then
	rm -rf kspaceduel.prev kspaceduel.org.prev
	mv kspaceduel.org kspaceduel.org.prev
	mv log-kspaceduel gitlog-kspaceduel svn2gitlog-kspaceduel kspaceduel.org.prev 2>/dev/null
fi

set -e

rm -rf kspaceduel
svn2git/svn-all-fast-export \
	--identity-map=kde-ruleset/account-map --add-metadata \
	--rules=kde-ruleset/kdegames/kspaceduel-rules \
	svn >svn2gitlog-kspaceduel 2>&1

# make a copy of the result so we can repeatedly test kspaceduel-postprocess.sh on it
cp -a kspaceduel kspaceduel.org

exec kde-ruleset/kdegames/kspaceduel-postprocess.sh
