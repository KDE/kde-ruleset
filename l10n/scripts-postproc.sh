#!/bin/bash

. $RULESETDIR/bin/filter-goodies

# Delete all backup refs and tags
delete_backup_tags

# A few commits are being marked as merges because they copied a file from
# another branch, but they aren't really merges. We'll "flatten" the merge,
# keeping the first parent only.
# This happens to be the case for *all* merge commits in the converted
# repository, so we don't need to list each revision to fix, just search all
# merges and process them all.

git rev-list --merges --parents --all | while read commit parent1 parent2; do
    echo "clear $commit"
    echo "$parent1 $commit"
done > generated-parentmap

git filter-branch \
    --parent-filter "$(cat generated-parentmap | $RULESETDIR/bin/add-parents.py)" \
    --tag-name-filter cat \
    -- --all

rm generated-parentmap
delete_fb_backups
