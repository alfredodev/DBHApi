#!/bin/bash
set -e

# Sync the contents of this directory where the site should have been built
SOURCE_DIR=./
REPO=https://${GIT_TOKEN}@github.com/PlainConcepts/DBHApi.git

if [ ! -d "$SOURCE_DIR" ]; then
  echo "SOURCE_DIR ($SOURCE_DIR) does not exist, build the source directory before deploying"
  exit 1
fi

if [ -n "$TRAVIS_BUILD_ID" ]; then

  echo TARGET_BRANCH: $TARGET_BRANCH
  echo DEPLOY_BRANCH: $DEPLOY_BRANCH
  echo REPO: $REPO

  if [ "$TRAVIS_BRANCH" != "$DEPLOY_BRANCH" ]; then
    echo "Travis should only deploy from the DEPLOY_BRANCH ($DEPLOY_BRANCH) branch"
    exit 0
  else
    if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
      echo "Travis should not deploy from pull requests"
      exit 0
    fi
  fi
fi



REPO_NAME=$(basename $REPO)
TARGET_DIR=$(mktemp -d /tmp/$REPO_NAME.XXXX)
REV=$(git rev-parse HEAD)

git config --global user.email ${GIT_EMAIL}
git config --global user.name ${GIT_USER}
git remote set-url origin $REPO
git clone --branch $TARGET_BRANCH $REPO ${TARGET_DIR}

rsync -rt --delete --exclude=".git" --exclude=".travis.yml" $SOURCE_DIR/ $TARGET_DIR/
cd $TARGET_DIR
git add -A .
git commit --allow-empty -m "Built from travis. commit $REV"
echo '2'
git push $REPO $TARGET_BRANCH
echo '3'

