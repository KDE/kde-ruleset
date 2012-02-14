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

class GitRepoTestCase(unittest.TestCase):
    def initRepo(self,repo):
        self.repo = repo
        self.longMessage = True
        self.renameDetector = diff_tree.RenameDetector(self.repo.object_store)

    def assertFileInTree(self, tree, path, msg=None):
        '''
        Checks whether a tree contains a file at the given path.

        This function supports subdirectories,
        such as assertFileInTree(tree, "dir/subdir/file").
        '''
        msg = self._formatMessage(msg, "file {0} not found in tree".format(path))
        try:
            (mode, sha) = tree.lookup_path(self.repo.get_object, path)
            self.assertTrue(mode & 0100000 != 0, msg)
        except KeyError:
            self.fail(msg)

    def getCommitChanges(self, commit):
        assert commit is not None
        self.assertEqual(len(commit.parents), 1, "commit should have only one parent")

        parentCommit = self.repo.commit(commit.parents[0])

        return diff_tree.tree_changes(self.repo.object_store,
                parentCommit.tree, commit.tree,
                False, self.renameDetector)

    def getRevsInRange(self, include, exclude):
        if not isinstance(include,list): include=[include]
        if not isinstance(exclude,list): exclude=[exclude]
        walker = self.repo.get_walker(include=include, exclude=exclude)
        for entry in walker:
            yield entry.commit

    def getRoots(self, include, exclude=[]):
        for commit in self.getRevsInRange(include, exclude):
            if len(commit.parents) == 0:
                yield commit

    def getFirstCommit(self, include, exclude=[]):
        for commit in self.getRevsInRange(include, exclude):
            pass
        return commit

    def assertNormalCommit(self, commit, msg="commit should have a single parent"):
        '''Checks whether the given commit is a normal commit with only one parent,
        that is, neither a merge nor a "root" commit.'''
        return self.assertEqual(len(commit.parents), 1, msg)

    def getRefOrBackup(self, refName):
        if not refName.startswith("refs/"):
            refName = "refs/heads/"+refName
        try:
            sha = self.repo.ref(refName)
            return sha
        except KeyError:
            if refName.startswith("refs/heads/"):
                regex = r'refs/tags/backups/{0}@\d+$'.format(refName[len("refs/heads/"):])
            else:
                regex = r'refs/backups/r\d+/{0}$'.format(refName[len("refs/"):])

            refs = self.repo.get_refs()
            results = [sha for ref,sha in refs.items() if re.match(regex, ref)]

            if len(results) == 1:
                return results[0]
            elif len(results) == 0:
                self.fail("ref '{0}' not found, and no backup refs found either".format(refName))
            else:
                self.fail("multiple backup refs found for '{0}'".format(refName))


class KTuberlingTests(GitRepoTestCase):
    def setUp(self):
        self.initRepo(Repo(repo_path))

    def testMasterRoot(self):
        roots = self.getRoots(include=[self.repo.branch("master")])
        roots = list(roots)
        self.assertEqual(len(roots), 1, "the master branch should have 1 root")

        root=roots[0]
        self.assertEqual(root.get_svn_rev(), 20670,
                        "the master branch root should be %d" % 20670)
        self.assertFileInTree(self.repo.tree(root.tree), "doc/en/index.html",
                        "the first commit should contain doc/en/index.html")

    def testDocRename(self):
        renameCommit = self.repo.commit_from_svnrev(20794)
        self.assertNormalCommit(renameCommit)

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
        self.assertNormalCommit(commitInQuestion)

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
        kde4Branch = self.getRefOrBackup("refs/workbranch/kde4")
        self.assertIsNotNone(kde4Branch, "branch kde4 not found")

        firstKde4Commit = self.getFirstCommit(kde4Branch, self.repo.branch("master"))
        self.assertEqual(firstKde4Commit.get_svn_rev(), 419958)

        # Get the last master commit before kde4's creation
        masterCommits = self.getRevsInRange(self.repo.branch("master"), [])
        commit = next(c for c in masterCommits if c.get_svn_rev() < 419754) # 419754 is when kde4 got branched

        self.assertEqual(firstKde4Commit.parents, [commit.id])

if __name__ == '__main__':
    unittest.main()
