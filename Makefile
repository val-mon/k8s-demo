# Define variables used in the Makefile
CLUSTER := compose-k8s
IMAGES  := api:demo web:demo
CURL_WEB := kubectl exec deploy/web -- python -c

# Define the default goal and phony targets
.PHONY: build compose compose-down cluster k8s scale heal cost demo clean
.DEFAULT_GOAL := demo

# Define a utility to print a section header
define section
	@printf "\n\n--------------------  [INFO]:  %s  --------------------\n" "$(1)"
endef

# Build the images
build:
	$(call section, DOCKER: BUILD)
	docker compose build

# Runs both services with Compose and calls `web`
compose: build
	$(call section, DOCKER: DEPLOYMENT)
	docker compose up -d
	@for i in 1 2 3 4 5; do curl -sf localhost:8000 && break; sleep 1; done; echo

# Pulls down the Compose services
compose-down:
	$(call section, DOCKER: COMPOSE DOWN)
	docker compose down

# Create the k8s cluster if it doesn't exist, and switch to it
cluster:
	$(call section, K8S: CLUSTER)
	@kind get clusters | grep -qx $(CLUSTER) || kind create cluster --name $(CLUSTER)
	kubectl config use-context kind-$(CLUSTER)

# Creates the kind cluster, loads the images, applies the manifests
k8s: build cluster
	$(call section, K8S: DEPLOYMENT)
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
	$(call section, K8S: SCALING TO 3 REPLICAS)
	kubectl scale deployment/api --replicas=3
	kubectl rollout status deployment/api
	@sleep 5
	$(CURL_WEB) "import urllib.request, json, time; [ (print(json.load(urllib.request.urlopen('http://localhost:8000'))['api_response']['hostname']), time.sleep(0.2)) for _ in range(15) ]"

# Deletes a pod and shows Kubernetes creating a new one
heal:
	$(call section,K8S: SELF-HEALING)
	@POD=$$(kubectl get pods -l app=api -o jsonpath='{.items[0].metadata.name}'); \
	echo "Deleting $$POD"; \
	kubectl delete pod $$POD --grace-period=1 --wait=false
	@sleep 3
	kubectl get pods -l app=api

# Counts the lines of config each approach needs
cost:
	$(call section, CONFIG COST)
	wc -l compose.yaml k8s/*.yaml

# Cleans up the demo
clean:
	$(call section, CLEANUP)
	-docker compose down
	-kind delete cluster --name $(CLUSTER)

# Launche the entire demo in one command
demo: compose compose-down k8s scale heal cost clean
