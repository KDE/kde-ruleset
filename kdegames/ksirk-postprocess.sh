#!/bin/bash

# why are those here at all? rules should have excluded them
git update-ref -d refs/workbranch/kconfig_new
git update-ref -d refs/workbranch/kconfiggroup_port
git update-ref -d refs/workbranch/kde4_jobflags
git update-ref -d refs/workbranch/kde4_kconfig
git update-ref -d refs/workbranch/kaction-cleanup1
git update-ref -d refs/workbranch/kaction-cleanup2
git update-ref -d refs/workbranch/kaction-cleanup3

