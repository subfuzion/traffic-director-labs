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
#
#
# Sample script for creating a cluster for deploying microservices app
# to demo Cloud Run for Anthos
#
# PREREQUISITES
# =============
# 1) Ensure you have created a project with billing enabled
# https://support.google.com/googleapi/answer/6251787?hl=en
#

CLUSTER="${CLUSTER:-cluster-1}"
ZONE="${ZONE:-us-central1-c}"
NODES="${NODES:-3}"
MAXNODES="${MAXNODES:-6}"
MACHINE="${MACHINE:-n2-standard-4}"
CHANNEL="${CHANNEL:-regular}"

gcloud services enable osconfig.googleapis.com
gcloud services enable trafficdirector.googleapis.com

PROJECT=`gcloud config get-value project`
gcloud projects add-iam-policy-binding ${PROJECT} \
   --member serviceAccount:${SERVICE_ACCOUNT_EMAIL} \
   --role roles/compute.networkViewer


gcloud container clusters create "${CLUSTER}" \
  --release-channel "${CHANNEL}" \
  --zone "${ZONE}" --num-nodes "${NODES}" --machine-type "${MACHINE}" \
  --scopes=https://www.googleapis.com/auth/cloud-platform \
  --enable-ip-alias \

gcloud container clusters get-credentials traffic-director-cluster \
    --zone "${ZONE}"

wget https://storage.googleapis.com/traffic-director/td-sidecar-injector.tgz
tar -xzvf td-sidecar-injector.tgz
cd td-sidecar-injector

# continue: https://cloud.google.com/traffic-director/docs/set-up-gke-pods-auto

