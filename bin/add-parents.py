#!/usr/bin/python
# -*- coding: utf-8 -*-

"""
Usage: git filter-branch --parent-filter "$(add-parents <parentmap>)"

Outputs a shell script for filter-branch --parent-filter, to add extra
parents to existing commits.

parentmap must be a filename with *git* revisions formatted like this:

f3ca1dab5c862581690a988ab41ac59a292095f8 1ddbe3918159275dd514aea734839583bfd24c59
fceef269d3a1c3e9321f5dd376f6b305176854d6 da3e27ee47f6016cff637045f29a74f90a4cdab2

For each line in the parentmap, the returned script will add the first
revision as a new parent for the second revision. In other words, it adds
a new first->second connection between revisions. Most probably, the first
revision will predate the second.
Only full SHA-1 IDs are supported, not general revision parameters,
like abbreviated hashes or tag names.

It seems to work better if you use --date-order in filter-branch, because
the date order usually matches the SVN revision order.

You can use bin/translateRevlist.py to convert a list of SVN revision
number pairs into git revision pairs usable in this script.
"""

import sys
import re

if len(sys.argv) < 2:
    parentmap = sys.stdin
elif len(sys.argv) == 2:
    if sys.argv[1] == '-':
        parentmap = sys.stdin
    else:
        parentmap = file(sys.argv[1], 'r')
else:
    print >> sys.stderr, "usage: add-parents [filename]"
    sys.exit(1)

code_template="""
parents=;
case $GIT_COMMIT in
%s
esac;
if [ -n "$parents" ]; then
    cat;
    for parent in $parents; do
        echo " -p $(map $parent)";
    done;
else
    cat;
fi
"""

# given mappings[A] = [B,C]: B and C will be added as new parents of A
mappings={}

for line in parentmap:
    match = re.match(r'([0-9a-fA-F]{40})\s+([0-9a-fA-F]{40})\b', line)
    if match:
        # add $1 as a parent of $2 = if commit is $2, add $1 as its parent
        newparent = match.group(1)
        child = match.group(2)

        if child not in mappings:
            mappings[child] = []

        mappings[child].append(newparent)

case_lines=[]
for child, parents in mappings.iteritems():
    case_lines.append("    %s) parents='%s';;" % (child, ' '.join(parents)))

print code_template % '\n'.join(case_lines)
