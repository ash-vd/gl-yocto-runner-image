#!/bin/bash
ORGANIZATION=$ORGANIZATION
ACCESS_TOKEN=$ACCESS_TOKEN

REG_TOKEN=$(curl -sX POST -H "Authorization: token ${ACCESS_TOKEN}" "https://api.github.com/repos/${ORGANIZATION}/actions/runners/registration-token" | jq .token --raw-output)

function wait_for_process () {
    local max_time_wait=30
    local process_name="$1"
    local waited_sec=0
    while ! pgrep "$process_name" >/dev/null && ((waited_sec < max_time_wait)); do
        echo "Process $process_name is not running yet. Retrying in 1 seconds"
        echo "Waited $waited_sec seconds of $max_time_wait seconds"
        sleep 1
        ((waited_sec=waited_sec+1))
        if ((waited_sec >= max_time_wait)); then
            return 1
        fi
    done
    return 0
}

processes=(dockerd)

for process in "${processes[@]}"; do
    wait_for_process "$process"
    if [ $? -ne 0 ]; then
        echo "$process is not running after max time"
        exit 1
    else 
        echo "$process is running"
    fi
done

cd /home/runner/actions-runner

./config.sh --url "https://github.com/${ORGANIZATION}" --token ${REG_TOKEN} --labels yocto,x64,linux --unattended

cleanup() {
    echo "Removing runner..."
    ./config.sh remove --unattended --token "${REG_TOKEN}"
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!