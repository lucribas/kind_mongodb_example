#!/bin/bash

export KUBECONFIG="$(pwd)/kubeconfig"

terraform init && \
terraform apply -auto-approve
