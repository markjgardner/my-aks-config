#!/bin/bash
#export TF_LOG="DEBUG"
terraform init \
-backend-config=resource_group_name=$TF_BACKEND_RESOURCE_GROUP \
-backend-config=storage_account_name=$TF_BACKEND_STORAGE_ACCOUNT \
-backend-config=container_name=$TF_BACKEND_CONTAINER_NAME \
-backend-config=key=akscluster 