TFVARS     := terraform.tfvars
TF         := terraform
AWS_REGION ?= us-east-1
ACCOUNT_ID  = $(shell aws sts get-caller-identity --query Account --output text)
ECR_URL     = $(ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/ecr-blacklist
IMAGE_TAG  ?= latest
IMAGE       = $(ECR_URL):$(IMAGE_TAG)

.PHONY: help init plan infra-create infra-destroy \
        docker-login docker-push deploy

help:
	@echo ""
	@echo "=== Infraestructura ==="
	@echo "  make init              Inicializa Terraform y descarga providers"
	@echo "  make plan              Muestra el plan sin aplicar cambios"
	@echo "  make infra-create      Crea toda la infraestructura (VPC + RDS + ECR + ECS + ALB)"
	@echo "  make infra-destroy     Destruye toda la infraestructura"
	@echo ""
	@echo "=== Docker / ECR ==="
	@echo "  make docker-login      Autentica Docker con ECR"
	@echo "  make docker-push       Build linux/amd64 + push a ECR (IMAGE_TAG=latest por defecto)"
	@echo "  make deploy            infra-create + docker-push"
	@echo ""
	@echo "  Opcional: IMAGE_TAG=v2 make docker-push"
	@echo ""

init:
	@test -f $(TFVARS) || (echo "ERROR: Crea terraform.tfvars primero (copia terraform.tfvars.example)" && exit 1)
	$(TF) init

plan: init
	$(TF) plan -var-file="$(TFVARS)"

infra-create: init
	$(TF) apply -var-file="$(TFVARS)" -auto-approve

infra-destroy: init
	$(TF) destroy -var-file="$(TFVARS)" -auto-approve

# ── Docker / ECR ──────────────────────────────────────────────────────────────

docker-login:
	@echo ">>> Autenticando Docker con ECR: $(ECR_URL)"
	aws ecr get-login-password --region $(AWS_REGION) | \
	  docker login --username AWS --password-stdin $(ECR_URL)

docker-push: docker-login
	@echo ">>> Build + push: $(IMAGE)"
	docker buildx build --platform linux/amd64 -t $(IMAGE) ../blacklist_app
	docker push $(IMAGE)

deploy: infra-create docker-push
	@echo ">>> Infra lista e imagen subida a ECR: $(IMAGE)"
