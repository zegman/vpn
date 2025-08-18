#!/usr/bin/env bash
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

set -euo pipefail

INSTANCE_NAME='vpn'
INSTANCE_TYPE='e2-micro'
PROJECT="$(gcloud config get project 2>/dev/null)"
LOCAL_PORT=${LOCAL_PORT:-8080}
APP=${APP:-'Google Chrome'}
APP_FLAGS=${APP_FLAGS:-'-incognito'}
SERVICE=${SERVICE:-'Wi-Fi'}

ZONE="${1:-$(gcloud compute zones list --format='value(name)' 2>/dev/null | shuf -n1)}"
export CLOUDSDK_COMPUTE_ZONE="$ZONE" CLOUDSDK_CORE_DISABLE_PROMPTS=1

cleanup() {
  echo
  echo 'Cleaning up...'
  networksetup -setsocksfirewallproxystate "$SERVICE" off >/dev/null 2>&1 || true
  gcloud compute instances delete \
    "$INSTANCE_NAME" \
    --project="$PROJECT" \
    --delete-disks=all \
    --quiet >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

echo "Creating instance in $ZONE..."
gcloud compute instances create \
  "$INSTANCE_NAME" \
  --project="$PROJECT" \
  --metadata=vmDnsSetting=ZonalOnly \
  --machine-type="$INSTANCE_TYPE" \
  --create-disk=boot=yes,image-family=debian-11,image-project=debian-cloud,size=10,type=pd-standard \
  --quiet >/dev/null 2>&1

IP="$(gcloud compute instances describe "$INSTANCE_NAME" --project="$PROJECT" --format='get(networkInterfaces[0].accessConfigs[0].natIP)' 2>/dev/null)"

printf 'Waiting for SSH on %s' "$IP"
until nc -z "$IP" 22 >/dev/null 2>&1; do
  printf '.'
  sleep 1
done
echo ' ready'

gcloud compute ssh "$INSTANCE_NAME" --project="$PROJECT" -- \
  -N -f -D "localhost:$LOCAL_PORT" \
  -o ExitOnForwardFailure=yes \
  -o ServerAliveInterval=30 \
  -o LogLevel=ERROR >/dev/null 2>&1

networksetup -setsocksfirewallproxy "$SERVICE" localhost "$LOCAL_PORT" >/dev/null

echo "SOCKS proxy on localhost:$LOCAL_PORT. Launching browser..."
open -ga "$APP" $APP_FLAGS >/dev/null 2>&1 || true

echo 'Press any key to exit'
read -n1 -s || true

echo 'Done.'
