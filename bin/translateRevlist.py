#!/usr/bin/python
# -*- coding: utf-8 -*-

import subprocess
import re
import sys

'''
Converts a list of SVN revisions into the corresponding git revisions in the
current repository.

The input file should contain numerical SVN revisions, one or more per line,
separated by whitespace. Any other non-numeric text will be ignored.
'''

def get_log_messages():
    p = subprocess.Popen(['git','log','-z', '--format=format:%H%x01%b', '--all'],
            stdout=subprocess.PIPE)

    rawdata = p.communicate()[0]
    data = dict((pair.split('\x01') for pair in rawdata.split('\x00')))
    p.wait()
    return data

def create_svn_map(msg_map):
    svnmap = {}
    for gitrev, msg in msg_map.items():
        match = re.search(r"^svn path=([^; ]+); revision=(\d+)", msg, re.MULTILINE)
        if match:
            svnrev = int(match.group(2))
            svnmap[svnrev] = gitrev

    return svnmap

def load_input(f):
    for line in f:
        line_revs = []
        for line_piece in re.split('\s+', line):
            try:
                line_revs.append(int(line_piece))
            except ValueError:
                pass
        yield line_revs

log_messages = get_log_messages()
svnmap = create_svn_map(log_messages)

input_file = file(sys.argv[1])

for revs_in_line in load_input(input_file):
    print ' '.join([svnmap[rev] for rev in revs_in_line])
