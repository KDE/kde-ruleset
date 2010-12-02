#!/usr/bin/python

import subprocess
import re
import sys

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
        svnline = msg[msg.rstrip().rfind('\n'):].strip()
        match = re.match(r"^svn path=([^; ]+); revision=(\d+)", svnline)
        if match:
            svnrev = int(match.group(2))
            svnmap[svnrev] = gitrev

    return svnmap

def load_parent_list(f):
    parent_list = {}
    for line in f:
        pair = line.split(' ')
        parent_list[int(pair[0])] = int(pair[1])
    return parent_list

log_messages = get_log_messages()
svnmap = create_svn_map(log_messages)

extra_parents = load_parent_list(file(sys.argv[1]))

for orig, newparent in extra_parents.items():
    print "%s %s" % (svnmap[orig], svnmap[newparent])
