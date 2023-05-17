#!/bin/bash
ORGANIZATION=$ORGANIZATION
ACCESS_TOKEN=$ACCESS_TOKEN

REG_TOKEN=$(curl -sX POST -H "Authorization: token ${ACCESS_TOKEN}" "https://api.github.com/repos/${ORGANIZATION}/actions/runners/registration-token" | jq .token --raw-output)

echo "ORGANIZATION"
echo ACCESS_TOKEN
echo "${REG_TOKEN}"

cd /home/docker/actions-runner

./config.sh --url "https://github.com/${ORGANIZATION}" --token ${REG_TOKEN} --labels yocto,x64,linux

cleanup() {
    echo "Removing runner..."
    ./config.sh remove --unattended --token "${REG_TOKEN}"
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!