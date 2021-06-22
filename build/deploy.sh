#!/bin/bash

registry=$1
name=$2
tag=$3

repository="${registry}/${name}"

deploy="helm upgrade --install --wait --namespace test"

deploy+=" --set image.repository=${repository} --set image.tag=${tag} $name ./charts"

eval $deploy