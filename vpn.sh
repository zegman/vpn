#!/bin/bash
#   Copyright 2023 Tamir Zegman
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

set -e

INSTANCE_NAME="vpn"
INSTANCE_TYPE="e2-micro"
PROJECT="$(gcloud config get project)"
LOCAL_PORT=8080
APP="Google Chrome"
APP_FLAGS="-incognito"

if [ -n "$1" ]; then
    ZONE="$1"
else
    ZONE=$(gcloud compute zones list --format="value(name)" | shuf -n1)
    echo "Using zone: $ZONE"
fi

export CLOUDSDK_COMPUTE_ZONE=$ZONE

gcloud compute instances create \
    "$INSTANCE_NAME" \
    --project="$PROJECT" \
    --metadata vmDnsSetting=ZonalOnly \
    --machine-type="$INSTANCE_TYPE" \
    --create-disk=boot=yes,image-family=debian-11,image-project=debian-cloud,size=10,type=pd-standard

echo "Waiting for instance to start"
until gcloud compute ssh "$INSTANCE_NAME" --command="true"; do
    sleep 1
    echo -n "."
done
echo
echo "Instance started"

gcloud compute ssh "$INSTANCE_NAME" -- \
    -D "localhost:$LOCAL_PORT" \
    -f \
    -q \
    -N

networksetup -setsocksfirewallproxy wi-fi localhost "$LOCAL_PORT"

open -a "$APP" $APP_FLAGS

echo "Press any key to exit"
read -n 1 -s

echo "Done"

networksetup -setsocksfirewallproxystate wi-fi off
gcloud compute instances delete \
    "$INSTANCE_NAME" \
    --project="$PROJECT" \
    --delete-disks=all \
    --quiet
