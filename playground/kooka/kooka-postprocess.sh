#!/bin/sh
##########################################################################
##									##
##  Filters to clean up the Kooka/libkscan repository after the		##
##  SVN->GIT conversion.						##
##									##
##########################################################################


#  Rebase the current development branch ('master') onto the point where
#  it was copied from 3.5 branch.  SVN commit 764798 (earlier 764781 was
#  a mistake, copying the whole of kdegraphics).

echo
git checkout 3.5
printf "Looking for branch point 3.5->master... "
ONTO=`git log --grep="backport fix mem leak" --pretty="format:%H"`
if [ ! -n "$ONTO" ]
then
	printf "not found!\n"
	exit 1
fi
printf "$ONTO\n";

echo "Rebasing..."
git checkout master
git rebase --root --onto $ONTO

#  Rebase the KDE3 development branch (no longer maintained) onto the
#  point where KDE4 development was started.  Handle the merge of
#  the README file.  SVN commit 859165.

echo
git checkout master
printf "Looking for branch point master->master-kde3... "
ONTO=`git log --grep="Ensure that the thumbnail view is up-to-date" --pretty="format:%H"`
if [ ! -n "$ONTO" ]
then
	printf "not found!\n"
	exit 1
fi
printf "$ONTO\n";


echo "Rebasing..."
git checkout master-kde3

git rebase --root --onto $ONTO
#  Sort out the merge
TMPFILE=`mktemp`; rm -rf $TMPFILE
mv kooka/README $TMPFILE
egrep -v '^(<<<<<<< |=======$|>>>>>>> )' $TMPFILE >kooka/README
git add kooka/README
git rebase --continue
rm -f $TMPFILE

#  Remove a couple of odd artifacts

echo; echo "Removing the backup reference for SVN commit 1037128..."
git update-ref -d refs/backups/r1037128/heads/master

echo; echo "Removing duplicated head of trunk branch..."
git checkout trunk
git reset --hard HEAD^

#  Fix up branch commits created by cvs2svn, originally these have the
#  author 'nobody@localhost' which is not accepted by git.kde.org.
#  Replace them with a dummy name/email.
#
#  Need to do this on for all branches and with a null filter for tags,
#  so that the structure is preserved.  See man page for git-filter-branch(1):
#  "The rewritten history will have different object names for all the
#  objects and will not converge with the original branch".

echo; echo "Filtering cvs2svn author name/email..."
git checkout master

#  From http://help.github.com/changing-author-info/
git filter-branch --env-filter '
	an="$GIT_AUTHOR_NAME"
	am="$GIT_AUTHOR_EMAIL"
	cn="$GIT_COMMITTER_NAME"
	cm="$GIT_COMMITTER_EMAIL"

	if expr "$GIT_COMMITTER_EMAIL" : "^nobody@" >/dev/null
	then
		an="CVS2SVN"
		am="cvs2svn@kde.org"
	fi
	if expr "$GIT_AUTHOR_EMAIL" : "^nobody@" >/dev/null
	then
		cn="CVS2SVN"
		cm="cvs2svn@kde.org"
	fi

	export GIT_AUTHOR_NAME="$an"
	export GIT_AUTHOR_EMAIL="$am"
	export GIT_COMMITTER_NAME="$cn"
	export GIT_COMMITTER_EMAIL="$cm"
	' --tag-name-filter "cat" -- --all

#  Clean up original refs from that, see "Checklist for Shrinking a Repository"
#  section in git-filter-branch(1).

echo; echo "Removing original references from filter..."
git for-each-ref --format="%(refname)" refs/original/ | xargs -n 1 git update-ref -d

#  All done

echo
exit 0
