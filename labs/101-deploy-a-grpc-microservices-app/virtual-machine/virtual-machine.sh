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

CLUSTER1ZONE="${ZONE:-us-central1-c}"
CLUSTER2ZONE="${ZONE:-asia-southeast1-b}"
MACHINE="${MACHINE:-e2-standard-2}"
IMAGE_LOCATION=gcr.io/google-samples/hello-app:1.0 #Replace me

#Uses the new Envoy Auto-installer:
#https://cloud.google.com/traffic-director/docs/set-up-gce-vms-auto
gcloud beta compute instance-templates create vm-tpl-${CLUSTER1ZONE} \
  --service-proxy enabled,tracing=ON,access-log=/var/log/envoy/access.log \
  --machine-type=${MACHINE} \
  --image-family=debian-9 --image-project=debian-cloud \
  --scopes=https://www.googleapis.com/auth/cloud-platform \
  --region=`echo $CLUSTER1ZONE | cut -f1-2 -d '-'` -q \
  --metadata-from-file startup-script=$(dirname "$0")/startup-script.sh \
  --metadata docker-image=$IMAGE_LOCATION
gcloud beta compute instance-templates create vm-tpl-${CLUSTER2ZONE} \
  --service-proxy enabled,tracing=ON,access-log=/var/log/envoy/access.log \
  --machine-type=${MACHINE} \
  --image-family=debian-9 --image-project=debian-cloud \
  --scopes=https://www.googleapis.com/auth/cloud-platform \
  --region=`echo $CLUSTER2ZONE | cut -f1-2 -d '-'` -q \
  --metadata-from-file startup-script=$(dirname "$0")/startup-script.sh \
  --metadata docker-image=$IMAGE_LOCATION

gcloud compute instance-groups managed create mig-${CLUSTER1ZONE} \
  --zone ${CLUSTER1ZONE} \
  --size=1 \
  --template=vm-tpl-${CLUSTER1ZONE}
gcloud compute instance-groups managed create mig-${CLUSTER2ZONE} \
  --zone ${CLUSTER2ZONE} \
  --size=1 \
  --template=vm-tpl-${CLUSTER2ZONE}
#gcloud compute instance-groups managed set-autoscaling mig-${CLUSTER1ZONE} #todo
#gcloud compute instance-groups managed set-autoscaling mig-${CLUSTER2ZONE} #todo

gcloud compute health-checks create http vm-td-health-check

gcloud compute backend-services create vm-bs --global \
 --load-balancing-scheme=INTERNAL_SELF_MANAGED \
 --connection-draining-timeout=30s \
 --health-checks vm-td-health-check

gcloud compute backend-services add-backend vm-bs \
  --instance-group mig-${CLUSTER1ZONE} \
  --instance-group-zone ${CLUSTER1ZONE} \
  --global
gcloud compute backend-services add-backend vm-bs \
  --instance-group mig-${CLUSTER2ZONE} \
  --instance-group-zone ${CLUSTER2ZONE} \
  --global

gcloud compute url-maps create vm-url-map \
   --default-service vm-bs

gcloud compute target-http-proxies create vm-target-proxy \
   --url-map=vm-url-map

gcloud compute forwarding-rules create vm-fr \
   --global \
   --load-balancing-scheme=INTERNAL_SELF_MANAGED \
   --address=10.128.0.4 \
   --target-http-proxy=vm-target-proxy \
   --ports=80
