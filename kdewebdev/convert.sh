#!/bin/bash

set -ex

# FIXME All this is very environment-specific
# and I shouldn't be hardcoding it!
# But for now it's more convenient...
export PATH=$PATH:$HOME/convrun/build:$HOME/svn2git

svnrepo=$HOME/svn
ruleset_root=$HOME/kde-ruleset

repo=$1
revlist=${repo}.revlist
rules=${repo}-rules

export RULESETDIR=${ruleset_root}

. $ruleset_root/bin/filter-goodies

if ! [[ -f $rules ]]; then
    echo "${rules} doesn't exist"
    exit 1
fi

src=$PWD
cd ~/result

if true; then
rm -rf log-$repo $repo log-residual-$repo residual-$repo

makerevlist kdesvn $src/$repo-rules > ${revlist}
svn-all-fast-export \
    --identity-map=${ruleset_root}/account-map \
    --revisions-file=${revlist} \
    --add-metadata --stats \
    --rules=$src/${rules} \
    ${svnrepo}
fi
rm -rf ${repo}-postproc
cp -a ${repo} ${repo}-postproc

(cd ${repo}-postproc &&
    ${ruleset_root}/bin/fix-tags &&
    delete_fb_backups
)
if [[ -x $src/${repo}-postproc ]]; then
    (cd ${repo}-postproc &&
        ${src}/${repo}-postproc &&
        delete_fb_backups
    )
fi
if [[ -f $src/${repo}-parentmap ]]; then
    (cd ${repo}-postproc &&
        ${ruleset_root}/bin/parent-adder ${src}/${repo}-parentmap &&
        delete_fb_backups
    )
fi
