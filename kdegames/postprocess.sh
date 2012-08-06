#!/bin/bash

# this script is to be started in the parent directory of kde-ruleset, svn2git
# and svn

if test ! -d kde-ruleset -o ! -d svn
then
	echo execute this in the directory with subdirectories kde-ruleset and svn
	exit 2
fi

export RULESETDIR=`pwd`/kde-ruleset
bindir="${RULESETDIR:?\$RULESETDIR must point to the kde-ruleset directory}/bin"
source "$bindir/filter-goodies"

do_module() {
	module=$1
	rm -rf $module
	cp -a $module.raw $module
	cd $module
	parentmap=$RULESETDIR/kdegames/$module-parentmap
	postprocess=$RULESETDIR/kdegames/$module-postprocess.sh
	treefilter=$RULESETDIR/kdegames/$module-tree-filter
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
		sh $postprocess
		delete_fb_backups
	fi

	change_cvs2svn_author
	delete_fb_backups

	if test -s $treefilter
	then
		echo $module: tree-filter...
		git filter-branch --tree-filter $treefilter --prune-empty --tag-name-filter cat -- --all
	fi
	delete_fb_backups

#	echo 'add revision tags for debugging...'
#	add_revision_tags

	git reflog expire --expire=now --all
#	git gc
	cd ..
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
done
