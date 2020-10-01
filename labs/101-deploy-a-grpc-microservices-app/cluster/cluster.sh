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

CLUSTER="${CLUSTER:-cluster-}"
CLUSTER1ZONE="${ZONE:-us-central1-c}"
CLUSTER2ZONE="${ZONE:-asia-southeast1-b}"
NODES="${NODES:-3}"
MAXNODES="${MAXNODES:-6}"
MACHINE="${MACHINE:-e2-standard-4}"
CHANNEL="${CHANNEL:-regular}"
PROJECT_ID=`gcloud config get-value project`
PROJECT_NUM=`gcloud projects describe $PROJECT --format="value(projectNumber)"`

gcloud services enable osconfig.googleapis.com
gcloud services enable trafficdirector.googleapis.com

gcloud container clusters create "${CLUSTER}-${CLUSTER1ZONE}" \
  --release-channel "${CHANNEL}" \
  --zone "${CLUSTER1ZONE}" --num-nodes "${NODES}" --machine-type "${MACHINE}" \
  --scopes=https://www.googleapis.com/auth/cloud-platform \
  --enable-ip-alias

gcloud container clusters get-credentials "${CLUSTER}-${CLUSTER1ZONE}" --zone "${CLUSTER1ZONE}"
export CONTEXT_CLUSTER_1=$(kubectl config current-context)

gcloud container clusters create "${CLUSTER}-${CLUSTER2ZONE}" \
  --release-channel "${CHANNEL}" \
  --zone "${CLUSTER2ZONE}" --num-nodes "${NODES}" --machine-type "${MACHINE}" \
  --scopes=https://www.googleapis.com/auth/cloud-platform \
  --enable-ip-alias

gcloud container clusters get-credentials "${CLUSTER}-${CLUSTER2ZONE}" --zone "${CLUSTER2ZONE}"
export CONTEXT_CLUSTER_2=$(kubectl config current-context)

#Auto Injection: https://cloud.google.com/traffic-director/docs/set-up-gke-pods-auto
wget -qO- https://storage.googleapis.com/traffic-director/td-sidecar-injector.tgz | tar xzv
cd td-sidecar-injector

sed -i.bak "s/your-project-here/$PROJECT_NUM/g" specs/01-configmap.yaml
sed -i.bak "s/your-network-here/default/g" specs/01-configmap.yaml

CN=istio-sidecar-injector.istio-control.svc

openssl req \
  -x509 \
  -newkey rsa:4096 \
  -keyout key.pem \
  -out cert.pem \
  -days 365 \
  -nodes \
  -subj "/CN=${CN}"

cp cert.pem ca-cert.pem

kubectl apply --cluster ${CONTEXT_CLUSTER_1} -f specs/00-namespaces.yaml
kubectl apply --cluster ${CONTEXT_CLUSTER_2} -f specs/00-namespaces.yaml

kubectl create --cluster ${CONTEXT_CLUSTER_1} secret generic istio-sidecar-injector -n istio-control \
  --from-file=key.pem \
  --from-file=cert.pem \
  --from-file=ca-cert.pem

kubectl create --cluster ${CONTEXT_CLUSTER_2} secret generic istio-sidecar-injector -n istio-control \
  --from-file=key.pem \
  --from-file=cert.pem \
  --from-file=ca-cert.pem

CA_BUNDLE=$(cat cert.pem | base64 | tr -d '\n')
sed -i "s/caBundle:.*/caBundle:\ ${CA_BUNDLE}/g" specs/02-injector.yaml

kubectl apply --cluster ${CONTEXT_CLUSTER_1} -f specs/
kubectl apply --cluster ${CONTEXT_CLUSTER_2} -f specs/

kubectl label --cluster ${CONTEXT_CLUSTER_1} namespace default istio-injection=enabled
kubectl label --cluster ${CONTEXT_CLUSTER_2} namespace default istio-injection=enabled

# continue: https://cloud.google.com/traffic-director/docs/set-up-gke-pods-auto

