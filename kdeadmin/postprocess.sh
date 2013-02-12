#!/bin/bash

if test -z $RULESETDIR; then
 echo "RULESETDIR not set"
 exit 1
fi

GIT=`which git`
CP=`which cp`
FIX_TAGS=$RULESETDIR/bin/fix-tags
PARENT_ADDER=$RULESETDIR/bin/parent-adder
TRANSLATE=$RULESETDIR/bin/translateRevlist.py
REMOVE_BACKUPS=$RULESETDIR/bin/remove-fb-backup-refs.sh
TMP_FILE=`pwd`/tmp_file
TMP_FILE2=`pwd`/tmp_file2

derive_names() {
  REPO=$REPO_or-postprocessed
  REPO_co=$REPO_or-checked-out
  PARENT_MAP=$RULESETDIR/kdeadmin/$REPO_or-parentmap
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

do_standard() {
  REPO_or=$1
  derive_names
  copy_and_enter
  fix_tags
  remove_backups
  add_parents
  remove_backups
  leave
}

# No arguments, process everything
if [ "$1z" == "z" ]; then
  do_standard kcron
  do_standard ksystemlog
  do_standard kdeadmin-strigi-analyzers
  do_standard kuser
else
  # otherwise process only what was passed as the first argument
  do_standard $1
fi
