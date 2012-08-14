#!/bin/bash

command -v optipng >/dev/null || { echo "optipng not installed. Aborting."; exit 1; }
command -v advdef >/dev/null || { echo "advdef not installed. Aborting."; exit 1; }

bindir="${RULESETDIR:?\$RULESETDIR must point to the kde-ruleset directory}/bin"
source "$bindir/filter-goodies"

tempdir=$(calc_tempdir recompress-images)
cachedir=$(calc_tempdir image-cache)

rm -rf "$tempdir";
mkdir -p "$cachedir";

export cachedir
export bindir

git filter-branch -f -d "$tempdir" --tag-name-filter cat --tree-filter "$(cat <<'EOF'

git ls-tree -r "$GIT_COMMIT" | egrep '\.(svgz|png)$' | while read objtype objmode objhash objname; do
    if [ ! -f "$cachedir/$objhash" ]; then
        if [ -z "$nl" ]; then echo >&2; nl=y; fi
        echo "${objname}:$(echo "$objhash" | cut -c1-10) not in cache, recompressing" >&2
        case $objname in
            *.svgz)
                $bindir/nullgzip.py "$objname" "$cachedir/$objhash"
                ;;
            *.png)
                optipng -o5 "$objname" &&
                advdef -z4 "$objname" &&
                cp "$objname" "$cachedir/$objhash"
                ;;
        esac
# make sure every file goes to cache, so if we cannot process something
# we get the error message only once. Triggered hundreds of times by
# carddecks/svg-xskat-german/images/shield.png in libkdegames. That file
# is like a pearl in an oyster - it is uncompressed svg.
	if [ ! -f "$cachedir/$objhash" ]; then
		cp "$objname" "$cachedir/$objhash"
	fi
    fi
    cp -f "$cachedir/$objhash" "$objname"
done
EOF
)" -- --all


