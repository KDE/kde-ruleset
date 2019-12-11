#!/usr/bin/env python2
# -*- coding: utf-8 -*-

from __future__ import print_function
import gzip
import sys

CHUNKSIZE = 4096

if len(sys.argv) != 3:
	print('Usage: %s <input.gz> <output.gz>' % sys.argv[0], file=sys.stderr)
	print('Creates an uncompressed gzip file from a gzip input file.', file=sys.stderr)
	sys.exit(0)

try:
	inFile = gzip.open(sys.argv[1], 'rb')
except IOError:
	print('Cannot open input file.', file=sys.stderr)
	sys.exit(1)
	
try:
	outFile = gzip.open(sys.argv[2], 'wb', 0)
except IOError:
	print('Cannot open output file.', file=sys.stderr)
	sys.exit(1)

try:
	with inFile, outFile:
		bytes = inFile.read(CHUNKSIZE)
		while bytes:
			outFile.write(bytes)
			bytes = inFile.read(CHUNKSIZE)
except IOError:
	print('Error while copying content from input file to output file.', file=sys.stderr)
	sys.exit(1)

