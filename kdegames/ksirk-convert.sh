#!/bin/bash

# this script is to be started in the parent directory of kde-ruleset, svn2git
# and svn

if test ! -d kde-ruleset -o ! -d svn
then
	echo execute this in the directory with subdirectories kde-ruleset and svn
	exit 2
fi

if test -d ksirk.org
then
	rm -rf ksirk.prev ksirk.org.prev
	mv ksirk.org ksirk.org.prev
	mv log-ksirk gitlog-ksirk svn2gitlog-ksirk ksirk.org.prev 2>/dev/null
fi

set -e

rm -rf ksirk
svn2git/svn-all-fast-export \
	--identity-map=kde-ruleset/account-map --add-metadata \
	--rules=kde-ruleset/kdegames/ksirk-rules \
	svn >svn2gitlog-ksirk 2>&1

# make a copy of the result so we can repeatedly test ksirk-postprocess.sh on it
cp -a ksirk ksirk.org

exec kde-ruleset/kdegames/ksirk-postprocess.sh
