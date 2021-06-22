#!/bin/bash

set -o errexit
set -o pipefail

source "build/init.sh"

bazel test --test_output=errors //src/...