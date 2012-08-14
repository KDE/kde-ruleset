#!/bin/bash

# Execute this script from the converted repository.

git update-ref -d refs/workbranch/kde4_jobflags
git update-ref -d refs/workbranch/kaction-cleanup1
git update-ref -d refs/workbranch/kaction-cleanup2

# otherwise workbranch/kgoldrunner-qgv will not be pushed
git branch qgv workbranch/kgoldrunner-qgv
