#!/usr/bin/env bash
# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

PROJECT=$(curl -s http://metadata.google.internal/computeMetadata/v1/project/project-id -H "Metadata-Flavor: Google")
ZONE=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/zone -H "Metadata-Flavor: Google" | cut -d '/' -f 4)
HOSTNAME=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/name -H "Metadata-Flavor: Google")
PROJECTNUM=$(curl -s http://metadata.google.internal/computeMetadata/v1/project/numeric-project-id -H "Metadata-Flavor: Google")
NETWORK=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/network -H "Metadata-Flavor: Google" | cut -d '/' -f 4)
export DOCKER_IMAGE=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/docker-image -H "Metadata-Flavor: Google")

if test -f "/.startup-ran"; then
  docker pull $DOCKER_IMAGE
  docker run -d --rm -e ZONE=$ZONE -e PORT=80 -e HOSTNAME=$HOSTNAME --network host $DOCKER_IMAGE
  echo "Skipping startup-script. Already run."
  exit 0
fi

export DEBIAN_FRONTEND=noninteractive

# Wait for package manager to finish
while (ps -A | grep apt) > /dev/null 2>&1; do
  echo 'Waiting for other package managers to finish'
  sleep 1
done

apt-get update -y
apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common dirmngr -y
apt-key adv --fetch-keys https://download.docker.com/linux/debian/gpg
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" -y
apt-get update -y
apt-get install docker-ce -y
gcloud auth configure-docker --quiet
docker pull $DOCKER_IMAGE
docker run -d --rm -e ZONE=$ZONE -e PORT=80 -e HOSTNAME=$HOSTNAME --network host $DOCKER_IMAGE

touch $HOME/.startup-ran