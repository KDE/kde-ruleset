#!/bin/bash

# Execute this script from the converted repository.

git update-ref -d refs/workbranch/kconfig_new
git update-ref -d refs/workbranch/kde4_kconfig
git update-ref -d refs/workbranch/kde4_jobflags
