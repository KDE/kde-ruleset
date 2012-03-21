#!/bin/bash

# this script is to be started in the parent directory of kde-ruleset, svn2git
# and svn

if test ! -d kde-ruleset -o ! -d svn
then
	echo execute this in the directory with subdirectories kde-ruleset and svn
	exit 2
fi

if test -d ksnake.org
then
	rm -rf ksnake.prev ksnake.org.prev
	mv ksnake.org ksnake.org.prev
	mv log-ksnake gitlog-ksnake svn2gitlog-ksnake ksnake.org.prev 2>/dev/null
fi

set -e

echo ksnake needs *.xpm files to be treated as binary but git will not 
echo recognize them as such because their beginning is text. Please
echo define '*.xpm -diff' in /etc/gitattributes or in any gitattributes
echo file specified by git config
echo 
rm -rf ksnake
#gdb --args svn2git/svn-all-fast-export \
svn2git/svn-all-fast-export \
	--identity-map=kde-ruleset/account-map --add-metadata \
	--rules=kde-ruleset/kdegames/ksnake-rules \
	svn >>svn2gitlog-ksnake 2>&1

# make a copy of the result so we can repeatedly test ksnake-postprocess.sh on it
cp -a ksnake ksnake.org

exec kde-ruleset/kdegames/ksnake-postprocess.sh
