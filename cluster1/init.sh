#!/bin/bash
TF_BACKEND_ACCESS_KEY="a4BDyf8PRAdBbi79gtgoRM+Rspf80CEkoMolMMByKHE1V+tsfqILqqrFfDY0MRAoswN2I4ZHdYOE+AStkmvbqQ=="
TF_LOG="DEBUG" terraform init \
-backend-config=resource_group_name=$TF_BACKEND_RESOURCE_GROUP \
-backend-config=storage_account_name=$TF_BACKEND_STORAGE_ACCOUNT \
-backend-config=container_name=$TF_BACKEND_CONTAINER_NAME \
-backend-config=key=akscluster
-backend-config=access_key=$TF_BACKEND_ACCESS_KEY./ini