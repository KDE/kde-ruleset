#!/bin/sh

set -u
set -e

ROOT=${PWD} #if run locally
if test -d /home/gitmaster; then #if run on a conversion server
    ROOT=/home/gitmaster
fi
RULESET=${ROOT}/kde-ruleset
ACCOUNTS=${RULESET}/account-map
SVN=${ROOT}/svn
SVN2GIT=${ROOT}/svn2git/svn-all-fast-export

if test ! -d "${RULESET}"; then
    echo "No ruleset found: ${RULESET}"
    exit 1
fi

if test ! -f "${ACCOUNTS}"; then
    echo "No account map found: ${ACCOUNTS}"
    exit 1
fi

if test ! -d ${SVN}; then
    echo "No SVN repo found: ${SVN}"
    exit 1
fi

if test ! -f ${SVN2GIT}; then
    echo "No svn2git executable found: ${SVN2GIT}"
    exit 1
fi

GAME=kgoldrunner
LOG=${PWD}/${GAME}.log

if test -d "${GAME}"; then
    echo "Removing old stuff..." >>${LOG} 2>&1
    rm -rf "${GAME}"
    rm -f "${LOG}"
    echo "Done." >>${LOG} 2>&1
    echo >>${LOG} 2>&1
fi

${SVN2GIT} --resume-from=145984 --add-metadata --identity-map ${ACCOUNTS} --rules ${RULESET}/kdegames/${GAME}-rules ${SVN} >>${LOG} 2>&1

. ./${GAME}-postprocessing.sh >>${LOG} 2>&1
