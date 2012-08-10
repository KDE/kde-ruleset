#!/bin/bash

# Execute this script from the converted repository.

git update-ref -d refs/workbranch/kconfiggroup_port
git update-ref -d refs/workbranch/kaction-cleanup2

# TODO r822136 does not move doc back from unmaintained
# all of doc will only reappear at r924952
