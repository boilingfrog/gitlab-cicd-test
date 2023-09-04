#!/bin/bash

set -o errexit
set -o pipefail

source "build/env.sh"
source "build/functions.sh"

bazel build //src/...

echo "build"
tag=$(auto_tag)
echo "build tag: $tag"

build_docker_images "${DOCKER_REGISTRY}" "${tag}"

git add .gitlab/deploy.yaml
git commit -m "test deploy..."
git tag $tag
git push origin --tags