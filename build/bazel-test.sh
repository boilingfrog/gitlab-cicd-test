#!/bin/bash

set -o errexit
set -o pipefail

source "build/env.sh"

bazel test --test_output=errors //src/...