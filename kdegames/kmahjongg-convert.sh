#!/bin/bash

# this script is to be started in the parent directory of kde-ruleset, svn2git
# and kde_svn

if test ! -d kde-ruleset -o ! -d kde_svn
then
	echo execute this in the directory with subdirectories kde-ruleset and kde_svn
	exit 2
fi

rm -rf kmahjongg.prev kmahjongg.org
if test -d kmahjongg
then
	mv kmahjongg kmahjongg.prev
	mv log-kmahjongg gitlog-kmahjongg svn2gitlog-kmahjongg kmahjongg.prev 2>/dev/null
fi

set -e

svn2git/svn-all-fast-export \
	--identity-map=kde-ruleset/account-map --add-metadata \
	--rules=kde-ruleset/kdegames/kmahjongg-rules \
	kde_svn >svn2gitlog-kmahjongg 2>&1

# make a copy of the result so we can repeatedly test kmahjongg-postprocess.sh on it
cp -a kmahjongg kmahjongg.org

exec kde-ruleset/kdegames/kmahjongg-postprocess.sh
