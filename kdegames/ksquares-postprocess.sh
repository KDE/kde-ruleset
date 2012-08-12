#!/bin/bash

# Execute this script from the converted repository.

git update-ref -d refs/workbranch/kconfig_new
git update-ref -d refs/workbranch/kde4_jobflags

# there is r721729 "merge KConfig branch" which
# does actually change something but this is not
# a merge - ksquares has never been changed in
# kde4_kconfig
git update-ref -d refs/workbranch/kde4_kconfig
