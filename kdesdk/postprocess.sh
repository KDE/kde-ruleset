#!/bin/bash

if test -z $RULESETDIR; then
 echo "RULESETDIR not set"
 exit 1
fi

GIT=/usr/bin/git
CP=/usr/bin/cp
FIX_TAGS=$RULESETDIR/bin/fix-tags
PARENT_ADDER=$RULESETDIR/bin/parent-adder
TRANSLATE=$RULESETDIR/bin/translateRevlist.py
REMOVE_BACKUPS=$RULESETDIR/bin/remove-fb-backup-refs.sh
TMP_FILE=`pwd`/tmp_file
TMP_FILE2=`pwd`/tmp_file2

derive_names() {
  REPO=$REPO_or-postprocessed
  REPO_co=$REPO_or-checked-out
  PARENT_MAP=$RULESETDIR/kdesdk/$REPO_or-parentmap
}

fix_tags() {
  echo "fixing tags"
  $FIX_TAGS
}

add_parents() {
  echo "adding parents according to $PARENT_MAP"
  $PARENT_ADDER $PARENT_MAP
}

copy_and_enter() {
  echo "copying $REPO_or to $REPO"
  $CP -R $REPO_or $REPO
  echo "entering $REPO"
  cd $REPO
}

leave() {
  echo "leaving $REPO"
  cd ..
}
remove_backups() {
  echo "removing backup refs"
  $REMOVE_BACKUPS
}

# kompare
do_kompare() {
  REPO_or=kompare
  derive_names
  copy_and_enter
  # kdevelop branched only libdiff2, so the commits look as if they removed everything else
  # recreate that branch by only cherry-picking the changes
  echo "572971
573861
574096
578348" > $TMP_FILE
  $TRANSLATE $TMP_FILE > $TMP_FILE2
  cd ..
  git clone $REPO $REPO_co
  cd $REPO_co
  (
    read line
    $GIT checkout -b kdevelop-teamwork $line
    while read line; do
      echo "cherry-picking $line"
      $GIT cherry-pick $line > /dev/null
    done
  ) < $TMP_FILE2
  rm $TMP_FILE $TMP_FILE2
  echo "pushing to origin"
  git push origin kdevelop-teamwork:refs/workbranch/kdevelop-teamwork -f
  cd ..
  rm -Rf $REPO_co
  cd $REPO
  echo "rewriting new commits to match committer to author"
  $GIT filter-branch --env-filter 'export GIT_COMMITTER_NAME=$GIT_AUTHOR_NAME
  export GIT_COMMITTER_EMAIL=$GIT_AUTHOR_EMAIL;
  export GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE' -- --max-count=3 refs/workbranch/kdevelop-teamwork
  remove_backups
  fix_tags
  remove_backups
  add_parents
  remove_backups
  leave
}

do_kompare
