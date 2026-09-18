# Docker Compose vs Kubernetes
A two-service Python app, run twice: once with Docker Compose, once on a local
Kubernetes cluster. The point is to compare how the services find each other,
and what Kubernetes adds on top.

- `api` — replies with its own hostname, so you can tell which container/pod answered
- `web` — calls `api` **by name** (`http://api:5000`) and returns what it got

The application code is identical in both setups. Only the orchestration changes.

## Requirements
- docker running
- [kind](https://kind.sigs.k8s.io/)
- kubectl
- make

## How to run the demo
- `make` : Cleans existing setup, builds the images, runs the app with Compose, then recreates the same app on a kind cluster, scales it, kills a pod, and compares the config size. Cleans up everything again at the end.

## What replaces what
| Docker Compose | Kubernetes |
|---|---|
| Implicit project network + Docker DNS | `Service` + CoreDNS |
| `docker compose up` | `Deployment` (declares the desired state) |
| `ports:` | `kubectl port-forward`, NodePort or Ingress |
| `environment:` | `env:`, ConfigMap, Secret |
| `depends_on:` | `readinessProbe` |
| Nothing (a dead container stays dead) | Self-healing and scaling |

## Notes
- Compose is a single file of 14 lines, the Kubernetes setup in comparison takes 73 lines across four manifests for the same result.
- With Compose, `docker ps` shows 2 containers. With kind it shows 1: the cluster
  node itself. The pods run inside it, next to CoreDNS, kube-proxy and the rest of
  the control plane.
