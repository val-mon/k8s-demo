CLUSTER := compose-k8s
IMAGES  := api:demo web:demo
CURL_WEB := kubectl exec deploy/web -- python -c

.PHONY: build compose compose-down cluster k8s scale heal cost demo clean
.DEFAULT_GOAL := demo

# Build the images
build:
	docker compose build

# Runs both services with Compose and calls `web`
compose: build
	docker compose up -d
	@for i in 1 2 3 4 5; do curl -sf localhost:8000 && break; sleep 1; done; echo

# Pulls down the Compose services
compose-down:
	docker compose down

# Create the k8s cluster if it doesn't exist, and switch to it
cluster:
	@kind get clusters | grep -qx $(CLUSTER) || kind create cluster --name $(CLUSTER)
	kubectl config use-context kind-$(CLUSTER)

# Creates the kind cluster, loads the images, applies the manifests
k8s: build cluster
	kind load docker-image $(IMAGES) --name $(CLUSTER)
	kubectl apply -f k8s/
	kubectl rollout restart deployment/api deployment/web
	kubectl rollout status deployment/api
	kubectl rollout status deployment/web
	@for i in 1 2 3 4 5 6 7 8 9 10; do \
		$(CURL_WEB) "import urllib.request; print(urllib.request.urlopen('http://localhost:8000').read().decode())" && break; \
		echo "waiting..."; sleep 2; \
	done

# Scales `api` to 3 replicas and shows requests spreading across pods
scale:
	kubectl scale deployment/api --replicas=3
	kubectl rollout status deployment/api
	@sleep 5
	$(CURL_WEB) "import urllib.request, json, time; [ (print(json.load(urllib.request.urlopen('http://localhost:8000'))['api_response']['hostname']), time.sleep(0.2)) for _ in range(15) ]"

# Deletes a pod and shows Kubernetes creating a new one
heal:
	@POD=$$(kubectl get pods -l app=api -o jsonpath='{.items[0].metadata.name}'); \
	echo "Deleting $$POD"; \
	kubectl delete pod $$POD --grace-period=1 --wait=false
	@sleep 3
	kubectl get pods -l app=api

# Counts the lines of config each approach needs
cost:
	wc -l docker-compose.yml k8s/*.yaml

# Cleans up the demo
clean:
	-docker compose down
	-kind delete cluster --name $(CLUSTER)

# Launche the entire demo in one command
demo: clean compose compose-down k8s scale heal cost clean
