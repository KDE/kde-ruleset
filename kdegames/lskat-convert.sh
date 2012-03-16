#!/bin/bash

# this script is to be started in the parent directory of kde-ruleset, svn2git
# and svn

if test ! -d kde-ruleset -o ! -d svn
then
	echo execute this in the directory with subdirectories kde-ruleset and svn
	exit 2
fi

if test -d lskat.org
then
	rm -rf lskat.prev lskat.org.prev
	mv lskat.org lskat.org.prev
	mv log-lskat gitlog-lskat svn2gitlog-lskat lskat.org.prev 2>/dev/null
fi

set -e

rm -rf lskat
svn2git/svn-all-fast-export \
	--identity-map=kde-ruleset/account-map --add-metadata \
	--rules=kde-ruleset/kdegames/lskat-rules \
	svn >svn2gitlog-lskat 2>&1

# make a copy of the result so we can repeatedly test lskat-postprocess.sh on it
cp -a lskat lskat.org

exec kde-ruleset/kdegames/lskat-postprocess.sh
