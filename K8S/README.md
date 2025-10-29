# Kubernetes Manifests for MERN stack

This folder contains a production-ready baseline for deploying a MERN application (MongoDB, Express/Node backend, React frontend) on Kubernetes.

The manifests are designed to work together within the `mern-monitoring` namespace and assume you will build and publish two container images:

- Backend image: `ghcr.io/your-org/mern-backend:latest`
- Frontend image: `ghcr.io/your-org/mern-frontend:latest`

Replace these image references with your own registry paths before deploying.

## Files overview

- `namespace.yaml`: Creates the `mern-monitoring` namespace to isolate the stack.
- `configmap.yaml`: Non‑secret configuration shared across services (ports, API URL, Mongo DB name, etc.).
- `secrets.yaml`: Sensitive data such as MongoDB root credentials and the `MONGO_URI` used by the backend.
- `mongodb-pvc.yaml`: PersistentVolumeClaim used by MongoDB to store data.
- `mongodb-deployment.yaml`: MongoDB `Deployment` with volume mount and credentials from `secrets.yaml`.
- `mongodb-service.yaml`: Stable `ClusterIP` service exposing MongoDB at `mongodb:27017` inside the cluster.
- `backend-deployment.yaml`: Node/Express backend `Deployment` with readiness/liveness probes.
- `backend-service.yaml`: `ClusterIP` service exposing backend at `backend:5000` inside the cluster.
- `frontend-deployment.yaml`: Nginx‑based frontend image serving the React build.
- `frontend-service.yaml`: `NodePort` service exposing the frontend on each node at TCP 30080.

## How services talk to each other

- The backend connects to MongoDB using `MONGO_URI` from `secrets.yaml`. Default URI: `mongodb://admin:adminpassword@mongodb:27017/mern?authSource=admin`.
- The frontend calls the backend by using the `REACT_APP_API_URL` value from `configmap.yaml`, set to `http://backend:5000` (cluster DNS name).

If you expose the backend publicly (e.g., via Ingress), update `REACT_APP_API_URL` accordingly and redeploy the frontend.

## Quickstart

1. Create the namespace and base configuration:

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml -n mern-monitoring
kubectl apply -f k8s/secrets.yaml -n mern-monitoring
```

2. Deploy MongoDB storage and service:

```bash
kubectl apply -f k8s/mongodb-pvc.yaml -n mern-monitoring
kubectl apply -f k8s/mongodb-deployment.yaml -n mern-monitoring
kubectl apply -f k8s/mongodb-service.yaml -n mern-monitoring
```

3. Deploy the application services:

```bash
# Replace image names in the YAMLs or use set image below
kubectl apply -f k8s/backend-deployment.yaml -n mern-monitoring
kubectl apply -f k8s/backend-service.yaml -n mern-monitoring
kubectl apply -f k8s/frontend-deployment.yaml -n mern-monitoring
kubectl apply -f k8s/frontend-service.yaml -n mern-monitoring
```

4. (Optional) Override images without editing manifests:

```bash
kubectl -n mern-monitoring set image deployment/backend backend=REGISTRY/mern-backend:TAG
kubectl -n mern-monitoring set image deployment/frontend frontend=REGISTRY/mern-frontend:TAG
```

## Accessing the app

- With the default `NodePort` service, the frontend is reachable at `http://<any-node-ip>:30080`.
- The frontend calls the backend at the internal DNS `http://backend:5000`. If you need external access to the backend, add an Ingress or switch the backend `Service` type.

## Configuration details

### ConfigMap (`configmap.yaml`)

- `BACKEND_PORT`: Container port for the backend (`5000`).
- `FRONTEND_PORT`: Exposed port for the frontend container (`80`).
- `MONGO_DB_NAME`: Default database name (`mern`).
- `MONGO_HOST`: DNS name for MongoDB service (`mongodb`).
- `REACT_APP_API_URL`: Base URL the frontend uses to call the backend (`http://backend:5000`).

### Secrets (`secrets.yaml`)

- `MONGO_INITDB_ROOT_USERNAME`, `MONGO_INITDB_ROOT_PASSWORD`: Root credentials used by the Mongo image at initialisation time.
- `MONGO_URI`: Connection string the backend uses. Defaults to:
  `mongodb://admin:adminpassword@mongodb:27017/mern?authSource=admin`.

Replace these values in production and consider using an external secret manager.

### MongoDB PVC (`mongodb-pvc.yaml`)

- Requests `5Gi` with storage class `standard`. Adjust to your cluster’s available classes and required size.

### MongoDB Deployment (`mongodb-deployment.yaml`)

- Uses official `mongo:6` image.
- Mounts the PVC at `/data/db`.
- Reads credentials from `mongo-secrets`.

### MongoDB Service (`mongodb-service.yaml`)

- `ClusterIP` service exposing port `27017` with selector `app: mongodb`.

### Backend Deployment (`backend-deployment.yaml`)

- 2 replicas for high availability.
- Exposes container port `5000`.
- Reads `PORT` from `configmap`, `MONGO_URI` from `secrets`.
- Health endpoints (`/health`) configured for readiness and liveness.

### Backend Service (`backend-service.yaml`)

- `ClusterIP` service exposing port `5000` with selector `app: backend`.

### Frontend Deployment (`frontend-deployment.yaml`)

- 2 replicas.
- Exposes container port `80` (assumes an nginx-based image that serves the React build).
- Reads `REACT_APP_API_URL` from `configmap`.

### Frontend Service (`frontend-service.yaml`)

- `NodePort` on `30080`. Change to `LoadBalancer` or add an Ingress for cloud environments.

## Common tweaks

- Use `LoadBalancer` for `frontend-service` on managed clouds:

```yaml
spec:
  type: LoadBalancer
```

- Add resource requests/limits per container in `deployments` for production sizing.
- Add an Ingress controller and an Ingress resource to expose the frontend on a domain with TLS.

## Cleanup

```bash
kubectl delete namespace mern-monitoring
```

## Notes

- Ensure your backend exposes a `/health` route for probes.
- If your frontend is compiled with environment variables at build time, rebuild the image after changing `REACT_APP_API_URL`.
