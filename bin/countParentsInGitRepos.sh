#!/bin/sh
#this script prints the number of parents of all git repositories in the current directory
#its important that you ensure any git repo only has 1 commit with no parents
for x in *; do pushd . > /dev/null ; cd $x 2>/dev/null && echo $x 2>/dev/null; git rev-list HEAD --parents 2>/dev/null | grep -v \ ; popd > /dev/null; done
