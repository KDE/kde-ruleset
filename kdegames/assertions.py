#!/usr/bin/python

# assertions for the ktuberling repository:
# - 20670 is the first revision in the master branch
# - first revision in master contains file doc/en/index.html
# - 20794 renames doc/en/index.html to doc/index.html
# - 22359 modifies doc/Makefile.am and nothing else
#
# - branch 2.0 exists
# - [69862,71236] are only revisions in 2.0 and not in master
# - 71236 is last revision of 2.0
# - 71236 modifies doc/index.docbook
#
# - branch kde4 or a backup tag exists
# - 419958 is the first commit in kde4 branch
# - 419958 has [max(rev) in master where rev<419958] as sole parent

from dulwich.repo import Repo
from dulwich.objects import Commit, Tree
from dulwich import diff_tree
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

# this is slow as hell! needs its own cache and stuff
def _commitFromSvnRev(repo, svnrev):
    for entry in repo.get_walker():
        if entry.commit.get_svn_rev() == svnrev:
            return entry.commit
    return None

Repo.commit_from_svnrev = _commitFromSvnRev

def changeIsModify(change, path):
    return change.type == "modify" and change.old.path == change.new.path == path
diff_tree.TreeChange.isModify = changeIsModify

def changeIsRename(change, old_path, new_path):
    return change.type == "rename" and change.old.path == old_path and change.new.path == new_path
diff_tree.TreeChange.isRename = changeIsRename

class KTuberlingTests(unittest.TestCase):
    def setUp(self):
        self.repo = Repo(repo_path)
        self.longMessage = True
        self.renameDetector = diff_tree.RenameDetector(self.repo.object_store)

    def assertFileInTree(self, tree, filename, msg=""):
        return self.assertTrue(self.repo.file_in_tree(tree, filename), msg)

    def testMasterRoot(self):
        roots = self.getRoots(include=[self.repo.branch("master")])
        roots = list(roots)
        self.assertEqual(len(roots), 1, "the master branch should have 1 root")

        root=roots[0]
        self.assertEqual(root.get_svn_rev(), 20670,
                        "the master branch root should be %d" % 20670)
        self.assertFileInTree(self.repo.tree(root.tree), "doc/en/index.html",
                        "the first commit should contain doc/en/index.html")

    def getCommitChanges(self, commit):
        assert commit is not None
        self.assertEqual(len(commit.parents), 1, "commit should have only one parent")

        parentCommit = self.repo.commit(commit.parents[0])

        return diff_tree.tree_changes(self.repo.object_store,
                parentCommit.tree, commit.tree,
                False, self.renameDetector)

    def testDocRename(self):
        renameCommit = self.repo.commit_from_svnrev(20794)
        self.assertIsNotNone(renameCommit, "commit not found")
        self.assertEqual(len(renameCommit.parents), 1, "commit should have a single parent")

        parentCommit = self.repo.commit(renameCommit.parents[0])

        # get the paths in doc/en in the tree before the commit
        parentTree = self.repo.tree(parentCommit.tree)
        parentDocEntry = parentTree.lookup_path(self.repo.get_object, "doc/en")
        parentDocTree = self.repo.tree(parentDocEntry[1])

        filesInParentTree = (entry.path for entry in parentDocTree.items())
        # Makefile.am is a bit of a special case
        expectedMoves = set(("doc/en/"+path, "doc/"+path) for path in filesInParentTree if path != "Makefile.am")

        changes = self.getCommitChanges(renameCommit)
        actualMoves = set((change.old.path, change.new.path) for change in changes if change.type == 'rename')

        self.assertEqual(expectedMoves, actualMoves, "20794 should move all documentation files")

    def testDocMakefileChange(self):
        commitInQuestion = self.repo.commit_from_svnrev(22359)
        self.assertIsNotNone(commitInQuestion, "commit 22359 not found")
        self.assertEqual(len(commitInQuestion.parents), 1, "commit should have a single parent")

        changes = list(self.getCommitChanges(commitInQuestion))
        self.assertEqual(len(changes), 1, "commit should make a single change")
        self.assertTrue(changes[0].isModify("doc/Makefile.am"), "commit should modify doc/Makefile.am")

    def test20BranchCommits(self):
        revsIn20 = list(self.getRevsInRange(self.repo.branch("2.0"), self.repo.branch("master")))
        revsIn20.reverse()
        self.assertEqual([rev.get_svn_rev() for rev in revsIn20], [69862, 71236],
                        "branch 2.0 doesn't have the expected commits")

        lastRevChanges = list(self.getCommitChanges(revsIn20[-1]))
        self.assertEqual(len(lastRevChanges), 1, "commit should make a single change")
        self.assertTrue(lastRevChanges[0].isModify("doc/index.docbook"), "commit should modify index.docbook")

    def testBranchKde4(self):
        kde4Branch = self.repo.ref("refs/tags/backups/kde4@439537")
        self.assertIsNotNone(kde4Branch, "branch kde4 not found")

        commitsInKde4 = list(self.getRevsInRange(kde4Branch, self.repo.branch("master")))
        firstKde4Commit = commitsInKde4[-1]
        self.assertEqual(firstKde4Commit.get_svn_rev(), 419958)

        # Get the last master commit before kde4's creation
        masterCommits = self.getRevsInRange(self.repo.branch("master"), [])
        commit = next(c for c in masterCommits if c.get_svn_rev() < 419754) # 419754 is when kde4 got branched

        self.assertEqual(firstKde4Commit.parents, [commit.id])

    def getRevsInRange(self, include, exclude):
        if not isinstance(include,list): include=[include]
        if not isinstance(exclude,list): exclude=[exclude]
        for entry in self.repo.get_walker(include=include, exclude=exclude):
            yield entry.commit

    def getRoots(self, include, exclude=[]):
        for entry in self.repo.get_walker(include=include, exclude=exclude):
            if len(entry.commit.parents) == 0:
                yield entry.commit

if __name__ == '__main__':
    unittest.main()
