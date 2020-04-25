#!/bin/bash

# Delete all backup refs and tags
for ref in $(git for-each-ref --format="%(refname)" refs/backups refs/tags/backups); do
    git update-ref -d "$ref";
done
