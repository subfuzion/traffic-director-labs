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

gcloud compute forwarding-rules delete -q --global vm-fr
gcloud compute target-http-proxies delete -q --global vm-target-proxy
gcloud compute url-maps delete -q --global vm-url-map
gcloud compute backend-services delete -q --global vm-bs 
gcloud compute health-checks delete -q --global vm-td-health-check
gcloud compute instance-groups managed delete -q mig-${CLUSTER1ZONE} --zone ${CLUSTER1ZONE}
gcloud compute instance-groups managed delete -q mig-${CLUSTER2ZONE} --zone ${CLUSTER2ZONE}
gcloud compute instance-templates delete -q vm-tpl-${CLUSTER1ZONE}
gcloud compute instance-templates delete -q vm-tpl-${CLUSTER2ZONE}
