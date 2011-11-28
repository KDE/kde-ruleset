#!/usr/bin/python

# assertions for the ktuberling repository:
# - 20670 is the first revision in the master branch
# - first revision in master contains file doc/en/index.html
# - 20794 renames doc/en/index.html to doc/index.html
# - 22359 modifies doc/Makefile.am and nothing else
# - branch 2.0 exists
# - [69862,71236] are only revisions in 2.0 and not in master
# - 71236 is last revision of 2.0
# - 71236 modifies doc/index.docbook
# - 419958 exists in branch kde4 or a backup tag
# - 419958 has max(rev) in master where rev<419958 as sole parent

from dulwich.repo import Repo
from dulwich.walk import Walker
from dulwich.objects import Commit, Tree
import re
import unittest

repo_path="."

svnrev_cache={}

# a few additions into the dulwich objects

def _getSvnRev(commit):
    '''
    Returns the SVN revision corresponding to the given commit.
    'commit' must be a dulwich.objects.Commit.
    '''
    if commit.id not in svnrev_cache:
        match = re.search(r"^svn path=([^; ]+); revision=(\d+)", commit.message, re.MULTILINE)
        if match:
            svnrev = int(match.group(2))
            svnrev_cache[commit.id] = svnrev

    return svnrev_cache[commit.id]

Commit.get_svn_rev = _getSvnRev

def _isFileInTree(repo, tree, path):
    '''
    Walks a tree, recursively, trying to find a file with the given path.
    '''
    # okay, actually I cheat and use lookup_path
    try:
        (mode, sha) = tree.lookup_path(repo.get_object, path)
        if mode & 0100000 != 0:
            return True
        else:
            return False
    except KeyError:
        return False
Repo.file_in_tree = _isFileInTree

def _shaFromBranch(repo, branch_name):
    return repo.ref("refs/heads/%s" % branch_name)
Repo.branch = _shaFromBranch

class KTuberlingTests(unittest.TestCase):
    def setUp(self):
        self.repo = Repo(repo_path)
        self.longMessage=True

    def testMasterRoot(self):
        roots = self.getRoots(include=[self.repo.branch("master")])
        roots = list(roots)
        self.assertEqual(len(roots), 1, "the master branch should have 1 root")
        root=roots[0]
        self.assertEqual(root.get_svn_rev(), 20670,
                        "the master branch root isn't what we expected")
        self.assertTrue(self.repo.file_in_tree(self.repo.tree(root.tree), "doc/en/index.html"))

    def getRoots(self, include, exclude=[]):
        for entry in self.repo.get_walker(include=include, exclude=exclude):
            if len(entry.commit.parents) == 0:
                yield entry.commit

if __name__ == '__main__':
    unittest.main()
