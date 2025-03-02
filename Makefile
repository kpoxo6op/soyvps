# ./Makefile - Simple Makefile for SoyVPS management

# Import environment variables from .env file
ifneq (,$(wildcard ./.env))
	include .env
	export
endif

.PHONY: help ssh apply ssh-clean

# This Makefile provides commands for managing the WireGuard VPS:
# - help: Displays available commands
# - ssh: Connects to the VM using its public IP
# - ssh-clean: Removes old SSH host keys and connects to the VM
# - apply: Runs terraform initialization and deployment

help:
	@echo "Available commands:"
	@echo "  help       - Show this help message"
	@echo "  ssh        - SSH to the Azure VM as azure user"
	@echo "  ssh-clean  - Remove old SSH host keys and SSH to the Azure VM"
	@echo "  apply      - Run terraform init and apply with auto-approval"
	@echo "  plan       - Run terraform plan"
ssh:
	@echo "Finding VM IP address..."
	@IP=$$(terraform output -raw vm_public_ip 2>/dev/null) && \
	if [ -z "$$IP" ]; then \
		echo "Error: Could not get VM IP address. Make sure terraform has been applied successfully."; \
		exit 1; \
	else \
		echo "Connecting to $$IP..."; \
		ssh azureuser@$$IP; \
	fi

ssh-clean:
	@echo "Finding VM IP address..."
	@IP=$$(terraform output -raw vm_public_ip 2>/dev/null) && \
	if [ -z "$$IP" ]; then \
		echo "Error: Could not get VM IP address. Make sure terraform has been applied successfully."; \
		exit 1; \
	else \
		echo "Removing old SSH host keys for $$IP..."; \
		ssh-keygen -f "$$HOME/.ssh/known_hosts" -R "$$IP" 2>/dev/null || true; \
		echo "Connecting to $$IP..."; \
		ssh azureuser@$$IP; \
	fi

plan:
	terraform init
	terraform plan

apply:
	terraform init
	terraform apply -auto-approve 