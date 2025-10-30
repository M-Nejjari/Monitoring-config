# MERN App Monitoring on Kubernetes

## Overview
This repo demonstrates a full-stack production-ready MERN app (Mongo, Express, React, Node) running on Kubernetes, with integrated monitoring using Prometheus and Grafana. Each component runs in its own container, managed by Kubernetes. Monitoring is production-grade, collecting application and infrastructure metrics.

---

## Project Structure

```
mern-monitoring/
├── app/
│   ├── backend/                  # Node.js/Express API (Prometheus metrics)
│   └── frontend/                 # React frontend
├── k8s/
│   ├── manifests/               # K8s manifests for app deployment/services
│   ├── monitoring/              # Monitoring configs (Prometheus, Grafana, Exporters)
│   └── scripts/                 # Helper scripts (eg: encode-secrets.ps1)
├── .gitignore
├── .dockerignore
└── README.md
```

### Folders and Key Files
- `app/backend/` — Node API with `/metrics` endpoint (Prometheus format)
- `app/frontend/` — React app (serves static content via Nginx or Node)
- `k8s/manifests/` — K8s Deployments & Services (backend, frontend, MongoDB)
- `k8s/monitoring/` — Monitoring stack (Helm values, ServiceMonitor, exporters)
- `k8s/scripts/encode-secrets.ps1` — PowerShell for safer secrets management
  
---

## How to Use

### Prerequisites
- Docker, Kubernetes cluster (minikube recommended), kubectl, and Helm
- DockerHub (for image publishing)

### 1. Build & Push Images
```
docker build -t <dockerhub-username>/mern-backend ./app/backend
docker build -t <dockerhub-username>/mern-frontend ./app/frontend
docker push <dockerhub-username>/mern-backend
docker push <dockerhub-username>/mern-frontend
```

### 2. Deploy to Kubernetes
```
kubectl apply -f k8s/manifests/
```

### 3. Deploy Monitoring (Prometheus+Grafana)
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prom prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace -f k8s/monitoring/prometheus-values.yaml
kubectl apply -f k8s/monitoring/
```
---

## Monitoring Details
- **Prometheus**: Collects metrics from backend (`/metrics`) & mongo-exporter
- **Grafana**: Dashboards from Prometheus data-source
- **MongoDB Exporter**: Exposes DB metrics for Prometheus
- **ServiceMonitor**: Points Prometheus to backend metrics endpoint

Visualize at Grafana dashboard (see README for port-forward instructions). Default user `admin`, password from K8s secret.

---

## Purpose of Key Files/Folders
- **Dockerfile** (each): Builds that component for portable deployment
- **K8s manifests**: Declarative, repeatable infrastructure setup
- **monitoring/**: Integrates monitoring platform for proactive alerting and metrics
- **encode-secrets.ps1**: Securely encodes secrets for Kubernetes

---

## How to Extend or Reproduce
1. Replace app logic with your own (Python, ML, Java — just add `/metrics` endpoint)
2. Follow the same containerization and K8s/monitoring pattern
3. For Python, use `prometheus_client` to expose `/metrics` in your Flask/FastAPI

---

## License
MIT






This is file serves as a blueprint to a setup involving promethus/ node-exporter/ mangodb/ mango-exporter/ grafana in order to monitor a MERN application 

The config is standard and aim to be flexible, i will add loki later and the alert manager
As i prefer working with python it will be the next step trying to adapt it that tech



PS : this is a project to learn this stack be nice pls and let me know what i can improve


