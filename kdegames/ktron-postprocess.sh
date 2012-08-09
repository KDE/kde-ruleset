#!/bin/bash

# Execute this script from the converted repository.

git update-ref -d refs/workbranch/kinstance-redesign
git update-ref -d refs/workbranch/kconfiggroup_port
git update-ref -d refs/workbranch/kaction-cleanup2
git update-ref -d refs/workbranch/kmainwindow-decoupling

# TODO r822136 does not move doc back from unmaintained
# all of doc will only reappear at r924952

rm -rf ../ksnakeduel.prev
test -d ../ksnakeduel && mv ../ksnakeduel ../ksnakeduel.prev
mv ../ktron ../ksnakeduel
