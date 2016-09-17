#!/bin/bash

# This script consolidates the git history of the publish repository by
# squashing commits older than the specified age into a new starting commit,
# then restoring subsequent commits from that point forward.

DRY_RUN=false
MAX_AGE='1 month ago'
FREQUENCY='1 week'
PUBLISH_DIR=_publish

while getopts 'da:f:D:' option; do
  case $option in
    d) DRY_RUN=true ;;
    a) MAX_AGE="$OPTARG" ;;
    f) FREQUENCY="$OPTARG" ;;
    D) PUBLISH_DIR="$OPTARG" ;;
  esac
done

cd $PUBLISH_DIR

# use schmitt trigger so script only runs every so often
if [ -z `git log -n1 --format=%H --until "$MAX_AGE $FREQUENCY"` ]; then
  exit 0
fi

GRAFT_COMMIT=`git log -n1 --format=%H --until "$MAX_AGE"`

if [ -z "$GRAFT_COMMIT" ]; then
  exit 0
fi

echo 'Consolidating history of build output repository...'

echo $GRAFT_COMMIT > .git/info/grafts

git filter-branch -f --msg-filter "
  if [ \$GIT_COMMIT == $GRAFT_COMMIT ]; then
    echo 'consolidate history'
  else
    cat
  fi"
rm -f .git/info/grafts

git reflog expire --expire=now --all
git gc --prune=now
if [ "$DRY_RUN" == "false" ]; then
  git push --force origin master
  cd ..
  rm -rf $PUBLISH_DIR
fi

echo 'Consolidation complete.'

exit 0
