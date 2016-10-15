#!/bin/sh

# The documentation branch was created with 'doc' alone (and missing CMakeLists.txt).
# To make the history look sane, import the rest of the source code into the branch.

base_rev=$(git rev-parse ':/revision=1247598')
cmakelists_sha=$(git rev-parse $base_rev:doc/CMakeLists.txt)

git filter-branch -f --index-filter "
    git read-tree $base_rev &&
    git rm -r --cached doc &&
    git read-tree --prefix doc/ \$GIT_COMMIT:doc &&
    git update-index --add --cacheinfo 100644,$cmakelists_sha,doc/CMakeLists.txt" \
-- doc-work
