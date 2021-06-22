#!/bin/bash

#set -x

files=$(git diff ${CI_COMMIT_BEFORE_SHA} ${CI_COMMIT_SHA} --name-only --diff-filter=ACM | grep -E -i ".go$")

pkgs=""
for file in ${files}
do
    pkg="${file%/*}"
    if [ $? -eq 0 ]; then
        if [[ $pkg != "vendor"* && $pkgs != *"$pkg"* ]]; then
            pkgs="${pkgs} ${pkg}"
        fi
    fi
done

if [[ "${pkgs}" = "" ]]; then
    echo "no changepkgs"
    exit 0
fi

echo -e "change packages:\n${pkgs}\n"

GO111MODULE=off golangci-lint run $pkgs -D errcheck