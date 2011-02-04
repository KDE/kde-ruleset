#!/bin/sh

EXPORT='svn-all-fast-export'
EXPORT_OPTIONS='--add-metadata --identity-map /home/gitmaster/kde-ruleset/account-map --resume-from=1'
RULES='--rules /home/git/mpyne/kdesrc-build-rules'
SVN='/home/gitmaster/svn'

${EXPORT} ${EXPORT_OPTIONS} ${RULES} ${SVN}
