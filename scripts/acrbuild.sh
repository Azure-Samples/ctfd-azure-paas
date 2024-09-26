#!/bin/bash
set -e

echo "Waiting on RBAC replication"
sleep $initialDelay

echo "$CONTENT" > Dockerfile

az acr build \
    --registry $acrName \
    --image $taggedImageName \
    --platform $platform \
    .
