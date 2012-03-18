#! /bin/sh

git tag | grep -P "backups/.*@\d+$" | xargs --no-run-if-empty -n 1 git tag -d
