#!/bin/bash

set -e
set -x

last_master=f617e24ace7bfb49458bcd8724eaa18119f58a0d
first_mpris=aa6d5445676e1079b8c15a465116220c4d799460
last_mpris=53b124b07da4432a741425ae1a4081b707024736

[[ $(git rev-parse master) == $last_master ]]

git remote add hein git://anongit.kde.org/scratch/hein/dragon.git
trap "git remote rm hein" 0
git fetch hein

[[ $(git rev-parse hein/master) == $last_mpris ]]
git rev-list master..hein/master | grep -q "$first_mpris"

echo "$first_mpris" "$last_master" > "$(git rev-parse --git-dir)/info/grafts"
git filter-branch master..hein/master
git update-ref refs/heads/master $(git rev-parse hein/master) $last_master

git for-each-ref --format="%(refname)" ${1:-refs/original/} | xargs --no-run-if-empty -n 1 git update-ref -d
