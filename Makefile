SHORT_COMMIT := $(shell git rev-parse --short HEAD)
NAMESPACE ?= playground
K8S_YAMLS_LOCATION ?= ./k8s/$(ENVIRONMENT)

.PHONY: docker-build
docker-build-and-push:
	docker build \
		--build-arg VERSION=$(RELEASE) \
		-t "$(IMAGE_URL):$(RELEASE)" \
		.

	docker push "$(IMAGE_URL):$(RELEASE)"

.PHONY: deploy
deploy: update-deployment-image apply-manifests

.PHONY: apply-manifests
apply-manifests:
	cd $(K8S_YAMLS_LOCATION) && kubectl -n $(NAMESPACE) apply -f .

.PHONY: update-deployment-image
update-deployment-image:
	@files=$$(find ${K8S_YAMLS_LOCATION} -type f \( -name "*.yml" -or -name "*.yaml" \) | grep deployment); \
	for i in $$files; do \
		patched=`openssl rand -hex 8`; \
		kubectl -n $(NAMESPACE) patch -f $$i -p '{"spec":{"template":{"spec":{"containers":[{"name":"demo-api-v1","image":"${IMAGE_URL}:${RELEASE}"}]}}}}' --local -o yaml > $$patched; \
		mv -f $$patched $$i; \
	done