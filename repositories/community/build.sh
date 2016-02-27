#!/bin/bash
set -e

. /vagrant/scripts/repositories.sh

export DOCKER_PULL_IMAGE="${DOCKER_PULL_IMAGE:-1}"
export REPOSITORY_DESCRIPTION="Community Repository"

BUILD_ARGS=(
  "app-text/cherrytree::and3k-sunrise"
  "--layman and3k-sunrise"
)

build_all "${BUILD_ARGS[@]}"
