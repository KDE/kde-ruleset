#!/bin/bash

set -e
set -x

last_master=54493adc2e0dc3ffa8817ef4a3bc3384ebdea7bc
last_mpris=cfae05592b9c1042aa26050f9c0813482937ba76

[[ $(git rev-parse master) == $last_master ]]

git remote add mpris git://anongit.kde.org/clones/juk/mpyne/juk-MPRIS.git
trap "git remote rm mpris" 0
git fetch --no-tags mpris

[[ $(git rev-parse mpris/master) == $last_mpris ]]

echo "5e78b28c775389a158459f87a1b5741095a66016" "$last_master" >> "$(git rev-parse --git-dir)/info/grafts"
echo "526bf549f5d31d0132570cebbb6581eba474a2a2" "77ac152b22341336b17f3c073ad0811502483594" >> "$(git rev-parse --git-dir)/info/grafts"

git filter-branch master..mpris/master
git update-ref refs/heads/master $(git rev-parse mpris/master) $last_master

git for-each-ref --format="%(refname)" ${1:-refs/original/} | xargs --no-run-if-empty -n 1 git update-ref -d
