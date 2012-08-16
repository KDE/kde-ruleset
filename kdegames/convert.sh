#!/bin/bash

# this script is to be started in the parent directory of kde-ruleset, svn2git
# and svn

if test ! -d kde-ruleset -o ! -d svn
then
	echo execute this in the directory with subdirectories kde-ruleset and svn
	exit 2
fi

export PATH=$PATH:svn2git
export RULESETDIR=`pwd`/kde-ruleset
export bindir="${RULESETDIR:?\$RULESETDIR must point to the kde-ruleset directory}/bin"

source "$bindir/filter-goodies"

do_module() {
	module=$1
	rulefile=kde-ruleset/kdegames/$module-rules
	revfile=kde-ruleset/kdegames/$module-revisions
	rm -rf $module $module.raw
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
	svn-all-fast-export $from $until $revisions \
		--identity-map=kde-ruleset/account-map --add-metadata \
		--debug-rules --rules=$rulefile svn >svn2gitlog-$module 2>&1
	mv log-$module gitlog-$module svn2gitlog-$module $module 2>/dev/null
	# $module.raw is without postprocessing
	rm -rf $module.raw ; mv $module $module.raw
}

postprocess() {
	module=$1
	if test ! -d $module.raw
	then
		echo $module.raw not found
		exit 1
	fi
	rm -rf $module
	cp -a $module.raw $module
	cd $module
	parentmap=$RULESETDIR/kdegames/$module-parentmap
	postprocess=$RULESETDIR/kdegames/$module-postprocess.sh
	treefilter=$RULESETDIR/kdegames/$module-tree-filter
	msgfilter=$RULESETDIR/kdegames/$module-msg-filter
	if test -r $parentmap
	then
		echo $module: parent-adder...
		$bindir/parent-adder $parentmap
	fi

	delete_backup_tags
	delete_fb_backups

	echo $module: fix-tags...
	$bindir/fix-tags
	delete_fb_backups

	# no game was changed by those branches
	git update-ref -d refs/workbranch/systray-rewrite
	git update-ref -d refs/workbranch/systray-rewrite-tng
	git update-ref -d refs/workbranch/kparts_urlargs_split
	git update-ref -d refs/workbranch/qdbus-api-changes

	# scons was a try to use the scons build system
	git update-ref -d refs/workbranch/kdegames-scons-v1

	if test -s $postprocess
	then
		echo $module: postprocess...
		source $postprocess
	fi

	change_cvs2svn_author
	delete_fb_backups

	if test -s $treefilter
	then
		echo $module: tree-filter...
		git filter-branch --tree-filter $treefilter --prune-empty --tag-name-filter cat -- --all
	fi
	delete_fb_backups

	if test -s $msgfilter
	then
		echo $module: msg-filter...
		git filter-branch --msg-filter $msgfilter --tag-name-filter cat -- --all
	fi
	delete_fb_backups

#	echo 'add revision tags for debugging...'
#	add_revision_tags

	git reflog expire --expire=now --all
	git gc --aggressive
	echo $module: finished
	echo
	cd ..
}

progname=$(basename $0)

if test $# -eq 0
then
	echo "
usage:

$progname lskat kajongg
or
$progname all"
	exit 2
fi

if test $# -eq 1 -a $1 = all
then
	set - $(cd kde-ruleset/kdegames; ls *-rules | sed 's/-rules//')
fi

for module in $*
do
	if test ! -r kde-ruleset/kdegames/$module-rules
	then
		echo no rules defined for $module
		continue
	fi
	test $progname = convert.sh && do_module $module
	postprocess $module
done
