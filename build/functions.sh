#!/bin/bash

function build_docker_images() {
  local docker_registry=$1
  local docker_tag=$2
  local base_image="liz2019/base-alpine:3.16"

  query=$(find_changes)

  if [ "$query" == "" ]; then
    print_log "no change and exit..."
    exit 0
  fi

  for b in ${query}; do
    b=${b//\/\/src/"/src"}
    if [[ $b == *test* ]]
        then
        continue
    fi

    local binary_file_path=$(find_binary "$b")

    if [ "$binary_file_path" == "" ]
          then
          continue
    fi

    local binary_name=$(get_binary_name "$b")
    local docker_build_path="dockerbuild/${binary_name}"
    local docker_file_path="${docker_build_path}/Dockerfile"
    local docker_image_tag="${docker_registry}/${binary_name}:${docker_tag}"

    print_log "Starting docker build for image: ${binary_name}"
    (
      rm -rf "${docker_build_path}"
      mkdir -p "${docker_build_path}"
      cp "${binary_file_path}" "${docker_build_path}/${binary_name}"

      cat <<EOF >"${docker_file_path}"
FROM ${base_image}
COPY ${binary_name} /usr/local/bin/${binary_name}

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
    name: production
  tags:
    - hw-runner

EOF

done

  print_log "Docker builds done"
}

function find_changes() {
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

function find_binary() {
  local -r lookfor="$1"

  IFS=': ' read -r -a array <<<"${lookfor}"

  local bin=$(find "bazel-bin/" -type f -path "*${array[0]}/${array[1]}_/${array[1]}" 2>/dev/null || true)

  echo -n $bin
}

function get_binary_name() {
  local -r lookfor="$1"
  IFS=': ' read -r -a array <<<"${lookfor}"
  name=${array[0]//\/\/src\//""}
  name=${name//\/src\//""}
  name=${name//\/cmd/""}
  name=${name//"service"/"svc"}
  name=${name//\//"-"}
  echo $name
}

function auto_tag() {
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

function print_log() {
  echo "++++++++++++ ${1}"
  shift
  for message; do
    echo "    ${message}"
  done
}
