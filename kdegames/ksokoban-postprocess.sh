#!/bin/bash

# Execute this script from the converted repository.

git update-ref -d refs/workbranch/kconfiggroup_port
git update-ref -d refs/workbranch/kaction-cleanup1
git update-ref -d refs/workbranch/kaction-cleanup2
git update-ref -d refs/workbranch/kmainwindow-decoupling
