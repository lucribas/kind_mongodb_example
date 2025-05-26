#!/bin/bash

export KUBECONFIG="$(pwd)/kubeconfig"


terraform destroy -auto-approve && \
kind delete cluster --name terraform-kind && \
rm kubeconfig
