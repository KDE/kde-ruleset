# export.sh
# Written by Trever Fischer <tdfischer@fedoraproject.org>
#
# To be ran on dewey.kde.org as part of migration for kdemm to git

svn-all-fast-export --add-metadata --identity-map /home/gitmaster/kde-ruleset/account-map --resume-from 52199 --rules "rules/kmix" /home/gitmaster/svn/
