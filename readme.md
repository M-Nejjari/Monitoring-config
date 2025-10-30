# MERN App Monitoring on Kubernetes

## Overview
This repository demonstrates a **production-ready full-stack MERN application** (MongoDB, Express, React, Node.js) running in containers orchestrated by **Kubernetes** and monitored using **Prometheus** and **Grafana**. 

> **If you are brand new to MERN, Kubernetes, or monitoring stacks: this README is for you! You’ll find step-by-step explanations guiding you through each piece.**

---

## Table of Contents
- [Project Structure](#project-structure)
- [Beginner Walkthrough: Folders and Files](#beginner-walkthrough)
- [Backend/Frontend — What Are They?](#backend-and-frontend)
- [Kubernetes Manifests — What They Do](#kubernetes-manifests)
- [Monitoring Stack — Prometheus, Grafana, and Exporters](#monitoring-stack)
- [Step-by-Step Usage](#how-to-use)
- [Extending or Troubleshooting](#how-to-extend-or-reproduce)
- [FAQs & Common Mistakes](#faqs-and-common-mistakes)
- [License](#license)

---

## Project Structure

```
mern-monitoring/
├── app/
│   ├── backend/        # Node.js/Express API (also exposes Prometheus metrics)
│   └── frontend/       # React frontend (built then served by Nginx)
├── k8s/
│   ├── manifests/      # Kubernetes YAMLs for all deployments/services
│   ├── monitoring/     # Prometheus/Grafana configs, exporters
│   └── scripts/        # Helper scripts e.g. encoding secrets
├── .gitignore
├── .dockerignore
└── README.md
```

---

## Beginner Walkthrough: Folders and Files
- **app/backend/**
  - Contains a Node.js/Express backend server.
  - Provides REST API and a `/metrics` endpoint (Prometheus format) letting you monitor server stats.
  - Includes a `Dockerfile` to package code into a portable container.
  - Uses `prom-client` to expose key metrics for Prometheus scraping.
- **app/frontend/**
  - Contains a basic React.js frontend you can extend.
  - Gets built, then served via an Nginx container (optimized for static sites).
  - Includes a `Dockerfile` which first builds the React app, then serves it using Nginx.

- **k8s/manifests/**
  - All the **Kubernetes resource definitions**, split into separate files for clarity:
    - **Deployments:** Describe how to run pods — e.g., `backend-deployment.yaml` runs 2 backend pods.
    - **Services:** Expose those pods so other containers or users can reach them.
    - **ConfigMaps & Secrets:** Hold settings (ConfigMap) and passwords (Secret) for your app.
    - **PVC:** Persistent Volume Claim, giving you durable storage for MongoDB.
- **k8s/monitoring/**
  - **Prometheus and Grafana config files.**
    - `prometheus-values.yaml`: Used by Helm, tells Prometheus how to find and scrape metrics.
    - `grafana-datasource.yaml`: Makes Grafana use Prometheus as its data source.
    - `service-monitor-backend.yaml`: Custom K8s resource, points Prometheus to backend`s /metrics endpoint.
    - `mongodb-exporter-deployment.yaml`: Deploys mongo exporter, letting Prometheus monitor MongoDB stats too.
- **k8s/scripts/**
  - Helper shell and PowerShell scripts. E.g., `encode-secrets.ps1` lets you safely base64-encode secrets for K8s.

---

## Backend and Frontend

> **Not sure what “backend” or “frontend” means?**
>
> - **Backend:** App logic, data processing, database access. Here it’s managed by a Node.js/Express app. Exposes REST endpoints and also `/metrics` for monitoring.
> - **Frontend:** What your users see — a single-page React website. It talks to the backend API (never directly to the DB!) and gets data to display.

**Backend main parts:**
- `server.js`: Starts an Express web server, connects to MongoDB, and exposes REST API **plus metrics**.
- Adds Prometheus metrics: Uses the `prom-client` library for Node.js. It tracks HTTP hits, latency, errors, etc., and exposes those stats at `/metrics`.
- Uses MongoDB for persistent storage.

**Frontend main parts:**
- React app you can extend (add pages, styling, calls to API, etc.).
- Built into static files, which are then served via Nginx in production.
- Dockerfile is multi-stage: build React assets, then copy them into an Nginx image.


---

## Kubernetes Manifests

> **What is Kubernetes?**
>
> It’s a powerful system for running many containers in production. It groups containers into pods and can automatically restart them, load-balance, update them, etc.

**Each YAML file in manifests defines a specific piece:**

- `namespace.yaml`: Keeps your resources in their own logical “folder.”
- `configmap.yaml`: Holds non-secret values (e.g., backend and frontend URLs/ports).
- `secrets.yaml`: Holds sensitive values (like your MongoDB password). Use provided script to secure them!
- `mongodb-pvc.yaml`: Allocates storage for MongoDB data, so DB persists even if pods are recreated.

**Deployments:**
- `mongodb-deployment.yaml`: Launches a MongoDB pod (plus PVC for data).
- `backend-deployment.yaml`: Runs your backend Node.js server, exposes `/metrics` for Prometheus.
- `frontend-deployment.yaml`: Runs your frontend React/Nginx site, makes it available as a service.

**Services:**
- Make your deployments reachable by DNS name inside the cluster. Example: backend is at `http://backend:5000`.
- **Frontend** runs as a NodePort service—you can reach it at `http://<node-ip>:30080`.


---

## Monitoring Stack

> **Why add monitoring?**
>
> In production you need “eyes on everything!” If something breaks, slows down, or errors increase, you want to catch it fast.

**Prometheus:**
- Is a **metrics scraper**. It visits endpoints in your app (e.g., `/metrics` on backend, `mongodb-exporter`) and collects stats every 30 seconds.
- In our project, it finds new targets to monitor via `ServiceMonitor` K8s resource (`service-monitor-backend.yaml`).
- Prometheus itself is deployed via Helm in the `monitoring` namespace for easy management.

**Grafana:**
- A dashboarding and alerting tool. It visualizes the metrics collected by Prometheus.
- Dashboards let you see live stats: DB health, API performance, errors, and much more.
- Data source for Grafana is set up by `grafana-datasource.yaml`.

**MongoDB Exporter:**
- A special container that exposes MongoDB-internal stats in Prometheus-compatible format.
- Deployed via `mongodb-exporter-deployment.yaml`.

---

## How to Use

### Prerequisites
- [Install Docker](https://docs.docker.com/get-docker), [kubectl](https://kubernetes.io/docs/tasks/tools/), [Helm](https://helm.sh/), and a Kubernetes cluster (try Minikube if new)
- Push images to a Docker registry you control (e.g., DockerHub)

### 1. Build & Push Images
```bash
docker build -t <dockerhub-username>/mern-backend ./app/backend
docker build -t <dockerhub-username>/mern-frontend ./app/frontend
docker push <dockerhub-username>/mern-backend
docker push <dockerhub-username>/mern-frontend
```

### 2. Deploy to Kubernetes
```bash
kubectl apply -f k8s/manifests/
```

### 3. Deploy Monitoring (Prometheus & Grafana)
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prom prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace -f k8s/monitoring/prometheus-values.yaml
kubectl apply -f k8s/monitoring/
```

---

## Monitoring Details (What Will Happen?)
- **Prometheus** will auto-discover the backend `/metrics` and mongo-exporter endpoints every 30s.
- **Grafana** will get all metrics from Prometheus and show dashboards.
- **MongoDB Exporter**: Monitors DB health/stats for Prometheus.
- **ServiceMonitor**: K8s resource to let Prometheus know where the metrics are.

Open the Grafana dashboard (see below for port-forward details). Default username is `admin`; password comes from a K8s secret (get with `kubectl get secrets -n monitoring`).

---

## Purpose of Key Files/Folders

- **Dockerfile:** Each component (backend/frontend) has one, lets you package, build, and run app anywhere.
- **K8s Manifests:** Declarative setup. No manual clicking in a UI—infra defined as code for reliability.
- **monitoring/**: Configs to help Prometheus/Grafana “see” your app and DB.
- **encode-secrets.ps1:** PowerShell script for quick, safe base64 encoding/secrets for Kubernetes.

---

## How to Extend or Reproduce

> - Swap in your own backend/frontend: as long as you expose a `/metrics` endpoint Prometheus understands, this template works for nearly any language (Python: use `prometheus_client` + Flask, Go, Java, etc).
> - Keep following the pattern: Dockerize your code. Create Kubernetes YAMLs. Add monitoring exporter/container. That’s it!

---

## FAQs and Common Mistakes

- **Q: My frontend can’t reach the backend!**
  - Double check: does the ConfigMap set `REACT_APP_API_URL` correctly? Remember, in Docker/K8s, you use internal DNS like `backend:5000`, not `localhost`.

- **Q: I see Mongo errors about authentication.**
  - Be sure your `secrets.yaml` **exactly matches** the MongoDB root password/username required by your DB pod.

- **Q: Prometheus shows no targets or “down.”**
  - Did you apply the ServiceMonitor YAML? Are the `/metrics` endpoints alive (visit in browser with port-forward to check)?

- **Q: I want access to Grafana/Prometheus from my laptop.**
  - Use port-forwarding:
    ```bash
    kubectl port-forward svc/prom-grafana -n monitoring 3000:80
    kubectl port-forward svc/prom-kube-prometheus-stack-prometheus -n monitoring 9090:9090
    ```
  - Visit http://localhost:3000 (Grafana), http://localhost:9090 (Prometheus).

- **Q: How do I see backend metrics?**
  - Port-forward backend service and open `/metrics` in browser.
    ```bash
    kubectl port-forward svc/backend -n mern-monitoring 5000:5000
    # then visit http://localhost:5000/metrics
    ```

- **Q: How do I debug failed pods?**
  - Use `kubectl describe pod/<podname>` and `kubectl logs <podname>`.

---

## License
MIT

---

> *This README serves as a step-by-step guide for anyone new to deploying and monitoring modern web apps with the MERN stack and Kubernetes. Feedback and suggestions are welcome! If you spot errors or want more explanations, open an issue or PR.*






This is file serves as a blueprint to a setup involving promethus/ node-exporter/ mangodb/ mango-exporter/ grafana in order to monitor a MERN application 

The config is standard and aim to be flexible, i will add loki later and the alert manager
As i prefer working with python it will be the next step trying to adapt it that tech



PS : this is a project to learn this stack be nice pls and let me know what i can improve


