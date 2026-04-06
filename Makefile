INVENTORY ?= inventories/dev/hosts.yml

.PHONY: install-deps bootstrap k3s argocd deploy verify ping ssh-key-only

install-deps:
	ansible-galaxy role install -r requirements.yaml -p roles/
	ansible-galaxy collection install -r requirements.yaml -p collections/

bootstrap:
	ansible-playbook -i $(INVENTORY) playbooks/bootstrap.yml

k3s:
	ansible-playbook -i $(INVENTORY) playbooks/k3s.yaml

argocd:
	ansible-playbook -i $(INVENTORY) playbooks/argocd.yaml

deploy: bootstrap k3s argocd

verify:
	ansible-playbook -i $(INVENTORY) playbooks/verify.yml

ping:
	ansible -i $(INVENTORY) devices -m ping

ssh-key-only:
	@if [ -z "$(HOSTS)" ]; then \
		echo "HOSTS is required. Example: make ssh-key-only HOSTS=master-node_01,worker-node_01"; \
		exit 1; \
	fi
	ansible-playbook -i $(INVENTORY) playbooks/ssh_key_only.yml --limit "$(HOSTS)"