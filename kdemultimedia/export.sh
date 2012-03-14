# export.sh
# Written by Trever Fischer <tdfischer@fedoraproject.org>
#
# To be ran on dewey.kde.org as part of migration for kdemm to git

for f in $@;do
	RULES="$f,$RULES"
done
RULES="${RULES}${HOME}/tdfischer/kdemultimedia-bottom-rules"
echo $RULES
svn-all-fast-export --add-metadata --identity-map /home/gitmaster/kde-ruleset/account-map --rules "$RULES" /home/gitmaster/svn/
