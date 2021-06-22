#!/bin/bash

#set -x

test::util:build_docker_images() {
  local docker_registry=$1
  local docker_tag=$2
  local base_image="alpine:3.7"

  query=$(test::util::find_changes)

  if [ "$query" == "" ]; then
    test::util::log "no change and exit..."
    exit 0
  fi


  for b in ${query}; do
    b=${b//\/\/src/"/src"}

    if [[ $b == *test* ]]
        then
        continue
    fi

    local binary_file_path=$(test::util::find_binary "$b")
    local binary_name=$(test::util::get_binary_name "$b")
    local docker_build_path="dockerbuild/${binary_name}"
    local docker_file_path="${docker_build_path}/Dockerfile"
    local docker_image_tag="${docker_registry}/${binary_name}:${docker_tag}"


    test::util::log "Starting docker build for image: ${binary_name}"
    (
      rm -rf "${docker_build_path}"
      mkdir -p "${docker_build_path}"
      cp "${binary_file_path}" "${docker_build_path}/${binary_name}"
      cat <<EOF >"${docker_file_path}"
FROM ${base_image}
COPY ${binary_name} /usr/local/bin/${binary_name}
RUN mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories \
  && apk update --no-cache \

ENTRYPOINT ["/usr/local/bin/${binary_name}"]
EOF
      docker build -q -t "${docker_image_tag}" "${docker_build_path}"
      docker push ${docker_image_tag}
    )


  cat <<EOF >>".gitlab/deploy.yaml"
${binary_name}:
  stage: deploy
  script:
    - bash build/deploy.sh ${docker_registry} ${binary_name} ${docker_tag}
  only:
    - tags
  when: manual
  environment:
    name: test
  tags:
    - golang-runner

EOF

done

  test::util::log "Docker builds done"
}

test::util::find_changes() {
  files=$(git diff $(git rev-list --tags --max-count=1) ${CI_COMMIT_SHA} --name-only --diff-filter=ACM | grep -E -i ".go$")

  paths=""
  for file in ${files}; do
    if [[ "${paths}" != "" ]]; then
      paths="${paths} union allpaths(//src/..., ${file})"
    else
      paths="allpaths(//src/..., ${file})"
    fi
  done

  query=$(bazel query "${paths}" --keep_going | grep //src/ | grep -v "go_default_library$" | grep -v "go$")
  echo -e "${query}"
}

test::util::find_binary() {
  local -r lookfor="$1"

  IFS=': ' read -r -a array <<<"${lookfor}"

  local bin=$(find "bazel-bin/" -type f -path "*${array[0]}/${array[1]}_/${array[1]}" 2>/dev/null || true)

  echo -n $bin
}

test::util::get_binary_name() {
  local -r lookfor="$1"
  IFS=': ' read -r -a array <<<"${lookfor}"
  name=${array[0]//\/\/src\//""}
  name=${name//\/src\//""}
  name=${name//\/cmd/""}
  name=${name//\//"-"}
  echo $name
}


test::util::auto_tag() {
  version=$(git describe --tags $(git rev-list --tags --max-count=1) 2>/dev/null || true)

  major=0
  minor=0
  build=0

  regex="([0-9]+).([0-9]+).([0-9]+)"
  if [[ $version =~ $regex ]]; then
    major="${BASH_REMATCH[1]}"
    minor="${BASH_REMATCH[2]}"
    build="${BASH_REMATCH[3]}"
  fi

  level=$(echo $CI_COMMIT_MESSAGE | cut -d' ' -f 3 | sed "s/^'\(.*\)'$/\1/" | cut -d'/' -f 1)

  if [[ $level == "feature" ]]; then
    minor=$((minor + 1))
    build=0
  elif [[ $level == "hotfix" ]]; then
    build=$((build + 1))
  elif [[ $level == "release" ]]; then
    major=$((major + 1))
    minor=0
    build=0
  else
    build=$((build + 1))
  fi

  echo "${major}.${minor}.${build}"
}

test::util::log() {
  timestamp=$(date +"[%m%d %H:%M:%S]")
  echo "+++ ${timestamp} ${1}"
  shift
  for message; do
    echo "    ${message}"
  done
}
