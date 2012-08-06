#!/bin/bash

# this script is to be started in the parent directory of kde-ruleset, svn2git
# and svn

if test ! -d kde-ruleset -o ! -d svn
then
	echo execute this in the directory with subdirectories kde-ruleset and svn
	exit 2
fi

do_module() {
	module=$1
	rulefile=kde-ruleset/kdegames/$module-rules
	revfile=kde-ruleset/kdegames/$module-revisions
	rm -rf $module.prev $module.org
	if test -d $module
	then
		mv $module.raw $module.raw.prev
		mv $module $module.prev
	fi
	if test -s $revfile
	then
		# use only revisions specified in that file
		revisions="--revisions-file=$revfile"
		from=""
		until=""
	else
		revisions=""
		from=$(grep 'first revision' $rulefile | sed 's/.*first revision *//')
		until=$(grep 'last revision' $rulefile | sed 's/.*last revision *//')
		test x$from = x || from="--resume-from=$from"
		test x$until = x || until="--max-rev=$until"
	fi
	echo $module: svn2git...
	svn2git/svn-all-fast-export $from $until $revisions \
		--identity-map=kde-ruleset/account-map --add-metadata \
		--debug-rules --rules=$rulefile svn >svn2gitlog-$module 2>&1
	mv log-$module gitlog-$module svn2gitlog-$module $module 2>/dev/null
	# $module.raw is without postprocessing
	rm -rf $module.raw ; mv $module $module.raw
}

if test $# -eq 0
then
	echo "
usage:

convert.sh lskat kajongg
or
convert.sh all"
	exit 2
fi

if test $# -eq 1 -a $1 = all
then
	set - $(cd kde-ruleset/kdegames; ls *-rules | sed 's/-rules//')
fi

for module in $*
do
	do_module $module
	r/postprocess.sh $module
done
