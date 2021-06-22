#!/bin/bash

set -o errexit
set -o pipefail

source "build/init.sh"
source "build/utils.sh"

bazel build //src/...
cat bazel-out/stable-status.txt

echo "build"
tag=$(test::util::auto_tag)
echo "build tag: $tag"

cat <<EOF >".gitlab/deploy.yaml"
deploy:
  stage: deploy
  script:
    - echo "deploy"
  only:
    - /^deploy-.*$/
  tags:
    - golang-runner

EOF

test::util:build_docker_images  "${DOCKER_REGISTRY}" "${tag}"

git add .
git commit -m "test deploy..."
git tag $tag
git push origin --tags