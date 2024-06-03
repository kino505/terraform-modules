#!/bin/bash
export APPLICATION=app1
export STATE_BUCKET=tf-state-827634242525-us-east-2
export TF_VAR_backend_infrastructure_bucket=$STATE_BUCKET
export REGION=us-east-2
export REF=dev
export TF_CLI_ARGS_apply="-auto-approve"
#export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
#env|grep TF_
work_dir_prefix="/tmp/_work_"

wd="${work_dir_prefix}/vpc"
if [ -d ${wd} ]; then
 rm -rf ${wd}
fi
mkdir -p ${wd}
export TF_CLI_ARGS_init="-backend-config='bucket=${STATE_BUCKET}' -backend-config='key=network/${APPLICATION}/${_module_name}.tfstate' -backend-config='region=${REGION}'"
terraform -chdir=${wd} init -from-module=git@github.com:kino5050/terraform-modules.git//aws/network/vpc?ref=${REF}
cp ./vars.auto.tfvars.json ${wd}/


tf_cmd=${1:-plan}
terraform -chdir=${wd} $tf_cmd

