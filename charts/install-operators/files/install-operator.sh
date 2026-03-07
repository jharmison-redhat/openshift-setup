#!/bin/bash

set -e

cd "$(dirname "$(realpath "$0")")"

while ! oc apply -f subscription.yaml; do
  sleep 5
done
