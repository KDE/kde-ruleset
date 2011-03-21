#!/usr/bin/env python
# -*- coding: utf-8 -*-

import subprocess
import re
import sys

'''
Converts a list of SVN revisions into the corresponding git revisions in the
current repository.

The input file should contain any number of SVN revisions per line, as decimal
numbers. If there's multiple revisions per line, they're usually separated by
whitespace, but any non-word character will work too.

In addition, you can follow the revision number with an @ sign and a path to
be matched exactly against the SVN path. This is useful when a single SVN
commit is converted into multiple git commits based on different SVN paths.
For example, to match a commit containing the following:

svn path=/branches/kstars/hdevalence/kstars/; revision=1121256

...you can use "1121256@/branches/kstars/hdevalence/kstars/". This path must
match *exactly*. It's not enough to give a prefix.

Any other text will be passed unmodified. Only the decimal numbers in the file
(possibly followed by @/path) will be converted, and everything else will stay
untouched.
'''

def get_log_messages():
    p = subprocess.Popen(['git','log','-z', '--format=format:%H%x01%b', '--all'],
            stdout=subprocess.PIPE)

    rawdata = p.communicate()[0]
    data = dict((pair.split('\x01') for pair in rawdata.split('\x00')))
    p.wait()
    return data

import collections

def create_svn_map(msg_map):
    svnmap = collections.defaultdict(lambda: {})
    for gitrev, msg in msg_map.items():
        match = re.search(r"^svn path=([^; ]+); revision=(\d+)", msg, re.MULTILINE)
        if match:
            svnrev = int(match.group(2))
            path = match.group(1)
            svnmap[svnrev][path] = gitrev

    return svnmap

def process_integers(line, func):
    result = ''
    last_idx = 0
    for match in re.finditer('\\b(\d+)(?:@(/[a-zA-Z0-9/_.-]+))?', line):
        result += line[last_idx:match.start()] # append text before this match
        result += func(int(match.group(1)), match.group(2)) # and append the processed integer we matched
        last_idx = match.end()
    result += line[last_idx:] # finally, append text after the last match (maybe only the final newline)
    return result

if len(sys.argv) < 2:
    input_file = sys.stdin
elif len(sys.argv) == 2:
    input_file = file(sys.argv[1], 'r')
else:
    print >> sys.stderr, "usage: translateRevlist.py [filename]"
    sys.exit(1)

print >> sys.stderr, "getting git log..."
log_messages = get_log_messages()
print >> sys.stderr, "done"
svnmap = create_svn_map(log_messages)

def get_match(svnrev, path=None):
    if path is None:
        return svnmap[svnrev].values()[0]
    else:
        return svnmap[svnrev][path]

for line in input_file:
    if line.startswith('#'):
        continue

    new_line = process_integers(line, get_match)
    sys.stdout.write(new_line)

# vim: set ts=4 sw=4 et tw=78:
