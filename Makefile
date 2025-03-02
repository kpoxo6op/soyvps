# ./Makefile - Simple Makefile for SoyVPS management

# Import environment variables from .env file
ifneq (,$(wildcard ./.env))
	include .env
	export
endif

.PHONY: help ssh apply plan

# This Makefile provides commands for managing the WireGuard VPS:
# - help: Displays available commands
# - ssh: Connects to the VM using its public IP (automatically handles SSH host key conflicts)
# - apply: Runs terraform initialization and deployment
# - plan: Runs terraform plan

help:
	@echo "Available commands:"
	@echo "  help       - Show this help message"
	@echo "  ssh        - SSH to the Azure VM (automatically handles SSH host key conflicts)"
	@echo "  apply      - Run terraform init and apply with auto-approval"
	@echo "  plan       - Run terraform plan"

ssh:
	@echo "Finding VM IP address..."
	@IP=$$(terraform output -raw vm_public_ip 2>/dev/null) && \
	if [ -z "$$IP" ]; then \
		echo "Error: Could not get VM IP address. Make sure terraform has been applied successfully."; \
		exit 1; \
	else \
		echo "Checking for SSH host key conflicts..."; \
		if ssh-keygen -F "$$IP" > /dev/null 2>&1; then \
			echo "Host key exists for $$IP. Testing SSH connection..."; \
			if ! ssh -o BatchMode=yes -o ConnectTimeout=5 azureuser@$$IP exit 2>/dev/null; then \
				echo "SSH connection failed. Removing old host key for $$IP..."; \
				ssh-keygen -f "$$HOME/.ssh/known_hosts" -R "$$IP" 2>/dev/null || true; \
			else \
				echo "SSH connection test successful."; \
			fi; \
		fi; \
		echo "Connecting to $$IP..."; \
		ssh azureuser@$$IP; \
	fi

plan:
	terraform init
	terraform plan

apply:
	terraform init
	terraform apply -auto-approve 