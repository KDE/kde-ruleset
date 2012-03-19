#! /bin/sh

git for-each-ref --format="%(refname)" ${1:-refs/original/} | \
    xargs --no-run-if-empty -n 1 git update-ref -d

git reflog expire --expire=now --all
