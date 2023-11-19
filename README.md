A MacOS bash script for temproarily launching an instance in Google Cloud Platform (GCP) to act as a web proxy and configure the local MacOS to use it.
After the proxy is set up, the scrpt:
- Launches an incognito Chrome tab.
- Waits for any key press and then terminates the instance and removes the local proxy configuration.

Usage:
vpn.sh [ZONE]

Where ZONE is a GCP zone such as us-west2-a. If no zone is specified, a random zone from the list of available zones is selected.

Dependncies:
- Google Cloud CLI (gcloud) - https://cloud.google.com/sdk/docs/install-sdk
- Chrome
