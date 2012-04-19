# export.sh
# Written by Trever Fischer <tdfischer@fedoraproject.org>
#
# To be ran on dewey.kde.org as part of migration for kdemm to git

for f; do
    svn-all-fast-export --add-metadata --identity-map /home/gitmaster/kde-ruleset/account-map --rules "$f" /home/gitmaster/svn/
done
