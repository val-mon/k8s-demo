# Docker Compose vs Kubernetes
A two-service Python app, run twice: once with Docker Compose, once on a local Kubernetes cluster.
- `api`: replies with its own hostname to identify which container/pod answered
- `web`: calls `api` and returns what it got

The point is to compare how the services find each other, and what Kubernetes adds on top.

## Requirements
- docker running
- kind
- kubectl
- make

## Run `make` to launch the demo
- Cleans existing setup
- Builds the images
- Runs the app with Compose
- Then recreates the same app on a kind cluster, scales it and kills a pod
- Compares the config size
- Cleans up everything again at the end

## Comparison
| | Docker Compose | Kubernetes |
|---|---|---|
| Find the other service | Project network via Docker DNS | CoreDNS via a `Service` |
| Start everything | `docker compose up` | `kubectl apply -f k8s/` |
| Expose a port | `ports: ["8000:8000"]` | `Service` |
| Recover from a crash | - | kubelet restarts it |
| Scale to 3 replicas | start more containers by hand | `kubectl scale --replicas=3` |
| Config size (this demo) | 1 file, 14 lines | 4 manifests, 81 lines |
