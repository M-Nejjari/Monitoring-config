#!/usr/bin/env bash
# Usage:
#   bash k8s/encode-secrets.sh -u admin -p adminpassword \
#     -r "mongodb://admin:adminpassword@mongodb:27017/mern?authSource=admin" \
#     -n travelmemory -s mongo-secrets

set -euo pipefail

USERNAME=""
PASSWORD=""
URI=""
NAMESPACE="travelmemory"
SECRET_NAME="mongo-secrets"

while getopts ":u:p:r:n:s:" opt; do
  case $opt in
    u) USERNAME="$OPTARG" ;;
    p) PASSWORD="$OPTARG" ;;
    r) URI="$OPTARG" ;;
    n) NAMESPACE="$OPTARG" ;;
    s) SECRET_NAME="$OPTARG" ;;
    *) ;;
  esac
done

if [[ -z "$USERNAME" ]]; then read -r -p "Enter Mongo root username: " USERNAME; fi
if [[ -z "$PASSWORD" ]]; then read -r -s -p "Enter Mongo root password: " PASSWORD; echo; fi
if [[ -z "$URI" ]]; then read -r -p "Enter Mongo connection URI: " URI; fi

b64() { printf "%s" "$1" | base64 -w0; }

B64_USER=$(b64 "$USERNAME")
B64_PASS=$(b64 "$PASSWORD")
B64_URI=$(b64 "$URI")

cat <<YAML
# Paste under data: in your Kubernetes Secret
apiVersion: v1
kind: Secret
metadata:
  name: ${SECRET_NAME}
  namespace: ${NAMESPACE}
type: Opaque
data:
  MONGO_INITDB_ROOT_USERNAME: ${B64_USER}
  MONGO_INITDB_ROOT_PASSWORD: ${B64_PASS}
  MONGO_URI: ${B64_URI}
YAML
