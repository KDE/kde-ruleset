#!/bin/bash

set -e

# Execute this script from the converted repository.

bindir="${RULESETDIR:?\$RULESETDIR must point to the kde-ruleset directory}/bin"
source "$bindir/filter-goodies"

echo 'parent-adder...'
$bindir/parent-adder $RULESETDIR/kdegames/libkmahjongg-parentmap

echo 'delete_fb_backups...'
delete_fb_backups
