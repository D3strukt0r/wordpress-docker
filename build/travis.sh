#!/bin/bash

set -eux

# Login to make sure we have access to private dockers and can upload to docker
if [[ -v DOCKER_PASSWORD && -v DOCKER_USERNAME ]]; then
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
fi

REPO_PHP=wordpress-php
docker build --target php -t "$REPO_PHP":latest .

REPO_NGINX=wordpress-nginx
docker build --target nginx -t "$REPO_NGINX":latest .

echo "Choosing tag to upload to... (Branch: '$TRAVIS_BRANCH' | Tag: '$TRAVIS_TAG')"
if [[ "$TRAVIS_BRANCH" == "master" ]]; then
    DOCKER_PUSH_TAG=latest
elif [[ "$TRAVIS_BRANCH" == "develop" ]]; then
    DOCKER_PUSH_TAG=nightly
elif [[ "$TRAVIS_TAG" != "" ]]; then
    DOCKER_PUSH_TAG=$TRAVIS_TAG
else
    echo "Skipping deployment because it's neither master, develop or a versioned tag"
    exit 0;
fi

if [[ -z $DOCKER_PASSWORD || -z $DOCKER_USERNAME ]]; then
    echo 'Docker credentials are not set'
    exit 1
fi

docker tag "$REPO_PHP" "$DOCKER_USERNAME"/"$REPO_PHP":"$DOCKER_PUSH_TAG"
docker push "$DOCKER_USERNAME"/"$REPO_PHP":"$DOCKER_PUSH_TAG"

docker tag "$REPO_NGINX" "$DOCKER_USERNAME"/"$REPO_NGINX":"$DOCKER_PUSH_TAG"
docker push "$DOCKER_USERNAME"/"$REPO_NGINX":"$DOCKER_PUSH_TAG"
