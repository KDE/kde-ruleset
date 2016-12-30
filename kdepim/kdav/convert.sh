#!/bin/bash

set -ex

# FIXME All this is very environment-specific
# and I shouldn't be hardcoding it!
# But for now it's more convenient...
export PATH=$PATH:$HOME/convrun/build:$HOME/svn2git

svnrepo=$HOME/svn
ruleset_root=$HOME/kde-ruleset

repo=kdav
revlist=${repo}.revlist
rules=${repo}-rules

export RULESETDIR=${ruleset_root}

. $ruleset_root/bin/filter-goodies

[[ -f $rules ]]

src=$PWD
cd ~/result

rm -rf log-$repo $repo log-residual-$repo residual-$repo

makerevlist kdesvn $src/$repo-rules > ${revlist}
time svn-all-fast-export \
    --identity-map=${ruleset_root}/account-map \
    --revisions-file=${revlist} \
    --add-metadata --stats --debug-rules \
    --rules=$src/${rules} \
    ${svnrepo} 2>${repo}.stderr | tee ${repo}.stdout

(cd ${repo} && git -c 'pack.threads=1' repack -adf)

rm -rf ${repo}-postproc
cp -al ${repo} ${repo}-postproc

[[ -f $src/${repo}-parentmap ]]
# FIXME don't use hardcoded path to parentadd-ng
(cd ${repo}-postproc &&
    $HOME/parentadd-ng/parentadd-ng.py . ${src}/${repo}-parentmap &&
    delete_fb_backups
)

# now get kdepim-runtime and stitch the old history

if [[ -d kdepim-runtime.git ]]; then
    (cd kdepim-runtime.git && git fetch --tags)
else
    git clone --bare git://anongit.kde.org/kdepim-runtime
fi

rm -rf kdav-final.git
cp -a kdepim-runtime.git kdav-final.git
cd kdav-final.git

git filter-branch --subdirectory-filter resources/dav --tag-name-filter cat -- --all
delete_fb_backups

git for-each-ref --format="%(refname)" | while read ref; do
    if [[ $(git ls-tree "$ref" | wc -l) -eq 0 ]]; then
        echo "Deleting ref with empty contents: $ref"
        git update-ref -d "$ref"
    fi
done
git for-each-ref --format="%(refname)" "refs/tags/enterprise*" | xargs --no-run-if-empty -n 1 git update-ref -d
git update-ref -d refs/heads/work/soc-pim

git remote add svn ../kdav-postproc
git fetch --tags svn

git update-ref refs/heads/KDE/4.5 $(git rev-parse refs/remotes/svn/KDE/4.5)
echo 4389cf352bd2c5cd04400a1b42695da002dd84ad $(git rev-parse refs/remotes/svn/master) > info/grafts
git filter-branch --tag-name-filter cat -- --all
delete_fb_backups
rm info/grafts
git remote rm svn

git reflog expire --expire=all --all
du -hs objects
git gc --aggressive --prune=now
du -hs objects
