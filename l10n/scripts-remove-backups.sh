#!/bin/bash

rm refs/backups/r1096480/tags/v4.4.1
rm refs/backups/r1147226/tags/v4.4.92
rm refs/backups/r1158493/tags/v4.5.0
rm refs/backups/r1159211/tags/v4.5.0
rm refs/backups/r1202153/tags/v4.5.4
rm refs/backups/r1240147/tags/v4.6.5 
rm refs/backups/r1383660/heads/master
rm refs/backups/r409203/heads/master

git tag -d backups/trunk_l10n-kde3@674880
git tag -d backups/stable_l10n-kde4@829973
git tag -d backups/stable_l10n-kde4@917189
git tag -d backups/stable_l10n-kde4@986141
git tag -d backups/stable_l10n-kde4@1084991
git tag -d backups/stable_l10n-kde4@1143809
git tag -d backups/stable_l10n-kde4@1213535
git tag -d backups/stable_l10n-kde4@1239282
git tag -d backups/KDE/4.14@1404817

# Recreated tags that do not contains anything substantially different
rm refs/backups/r591395/tags/v3.5.5
rm refs/backups/r519761/tags/v3.5.2
rm refs/backups/r467490/tags/v3.4.3
