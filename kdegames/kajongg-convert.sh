#!/bin/bash

# this script is to be started in the parent directory of kde-ruleset, svn2git
# and kde_svn

if test ! -d kde-ruleset -o ! -d kde_svn
then
	echo execute this in the directory with subdirectories kde-ruleset and kde_svn
	exit 2
fi

rm -rf kajongg.prev kajongg.org
if test -d kajongg
then
	mv kajongg kajongg.prev
	mv log-kajongg gitlog-kajongg svn2gitlog-kajongg kajongg.prev 2>/dev/null
fi

set -e

svn2git/svn-all-fast-export --resume-from=895140 \
	--identity-map=kde-ruleset/account-map --add-metadata \
	--rules=kde-ruleset/kdegames/kajongg-rules \
	kde_svn >svn2gitlog-kajongg 2>&1
