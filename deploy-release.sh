#!/bin/bash
set -e

# Sync the contents of this directory where the site should have been built
SOURCE_DIR=./

if [ ! -d "$SOURCE_DIR" ]; then
  echo "SOURCE_DIR ($SOURCE_DIR) does not exist, build the source directory before deploying"
  exit 1
fi

REPO=$(git config remote.origin.url)

if [ -n "$TRAVIS_BUILD_ID" ]; then
  # When running on Travis we need to use SSH to deploy to GitHub
  #
  # The following converts the repo URL to an SSH location,
  # decrypts the SSH key and sets up the Git config with
  # the correct user name and email (globally as this is a
  # temporary travis environment)
  #
  # Set the following environment variables in the travis configuration (.travis.yml)
  #
  #   TARGET_BRANCH    - The branch where will be pushed the content of the deploy branch
  #   DEPLOY_BRANCH    - The only branch that Travis should deploy from
  #   ENCRYPTION_LABEL - The label assigned when encrypting the SSH key using travis encrypt-file
  #   GIT_NAME         - The Git user name
  #   GIT_EMAIL        - The Git user email
  #
  echo TARGET_BRANCH: $TARGET_BRANCH
  echo DEPLOY_BRANCH: $DEPLOY_BRANCH
  echo ENCRYPTION_LABEL: $ENCRYPTION_LABEL
  echo GIT_NAME: $GIT_NAME
  echo GIT_EMAIL: $GIT_EMAIL

  if [ "$TRAVIS_BRANCH" != "$DEPLOY_BRANCH" ]; then
    echo "Travis should only deploy from the DEPLOY_BRANCH ($DEPLOY_BRANCH) branch"
    exit 0
  else
    if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
      echo "Travis should not deploy from pull requests"
      exit 0
    else

      REPO=${REPO/git:\/\/github.com\//git@github.com:}



      git config --global user.name "$GIT_NAME"
      git config --global user.email "$GIT_EMAIL"
      git config --global github.token "$GIT_TOKEN"
    fi
  fi
fi


REPO_NAME=$(basename $REPO)
echo REPO_NAME: ${REPO_NAME}

TARGET_DIR=$(mktemp -d /tmp/$REPO_NAME.XXXX)
echo TARGET_DIR: ${TARGET_DIR}
echo '0'
ssh -vT git@github.com

REV=$(git rev-parse HEAD)
git clone --branch ${TARGET_BRANCH} ${REPO} ${TARGET_DIR}
echo '1'
rsync -rt --delete --exclude=".git" --exclude=".travis.yml" $SOURCE_DIR/ $TARGET_DIR/
cd $TARGET_DIR
git add -A .
git commit --allow-empty -m "Built from commit $REV"
echo '2'
git push $REPO $TARGET_BRANCH
echo '3'

