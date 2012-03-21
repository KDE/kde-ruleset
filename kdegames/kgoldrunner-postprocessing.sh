#!/bin/sh

set -u
set -e

GAME=kgoldrunner
LOG=${PWD}/${GAME}.log

if test ! -d "${GAME}"; then
    echo "No repo dir found." >>${LOG} 2>&1
    exit 1
fi

echo "Changing dir..." >>${LOG} 2>&1
cd ${GAME}
echo "Done." >>${LOG} 2>&1
echo >>${LOG} 2>&1

echo "Running log..." >>${LOG} 2>&1
git log --graph >log.temp
echo "Done." >>${LOG} 2>&1
echo >>${LOG} 2>&1

echo "Running filter-branch..." >>${LOG} 2>&1
git filter-branch --tree-filter 'dos2unix --keepdate gamedata/games.dat || echo' --prune-empty --tag-name-filter cat -- --all >>${LOG} 2>&1
echo "Done." >>${LOG} 2>&1
echo >>${LOG} 2>&1

echo "Cleaning up..." >>${LOG} 2>&1
rm -r .git/refs/original # is 'git update-ref -d' better?
git reflog expire --expire=now --all
git prune
echo "Done." >>${LOG} 2>&1
echo >>${LOG} 2>&1

echo "Running log..." >>${LOG} 2>&1
git log --graph >log2.temp
echo "Done." >>${LOG} 2>&1
echo >>${LOG} 2>&1

echo "Creating diff..." >>${LOG} 2>&1
diff -u log.temp log2.temp >../${GAME}.log.diff
echo "Done." >>${LOG} 2>&1
echo >>${LOG} 2>&1

echo "Cleaning up..." >>${LOG} 2>&1
rm log.temp log2.temp
echo "Done." >>${LOG} 2>&1

echo "Done." >>${LOG} 2>&1

