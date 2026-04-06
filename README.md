## K3s + Argo CD Homelab Bootstrap (Ansible)

This repository automates:

- Bootstrap of Linux nodes for K3s
- K3s cluster installation (hybrid server + worker agent)
- Argo CD installation on the K3s server
- Verification of cluster and Argo CD state
- SSH key migration and optional key-only SSH hardening

Current topology:

- `master_node` group: K3s server (hybrid node)
- `worker_node` group: K3s agent (worker)
- `devices` group: all managed nodes

## Repository Structure

- `inventories/dev/hosts.yml`: inventory groups and host mapping
- `inventories/dev/group_vars/`: group-level variables
- `inventories/dev/host_vars/`: host-specific variables
- `playbooks/bootstrap.yml`: system bootstrap + hostname/mDNS setup
- `playbooks/k3s.yaml`: K3s server and agent installation
- `playbooks/argocd.yaml`: Argo CD installation
- `playbooks/verify.yml`: verification checks
- `playbooks/ssh_key_only.yml`: SSH key migration/hardening
- `Makefile`: common automation commands

## Prerequisites

- Linux/macOS control machine with:
	- Ansible installed
	- SSH access to nodes
	- `make`
- Node user has sudo privileges

## Inventory and Variables

Default inventory path used by Make targets:

- `inventories/dev/hosts.yml`

Core connection variables are expected in:

- `inventories/dev/group_vars/all/secrets.yml`

Important values include:

- `vault_master_node_host`
- `vault_worker_node_host`
- `vault_private_key_master_node_01`
- `vault_private_key_worker_node_01`
- `vault_public_key_path`

## Quick Start

1. Install dependencies

```bash
make install-deps
```

2. Verify connectivity

```bash
make ping
```

3. Bootstrap nodes

```bash
make bootstrap
```

4. Install K3s

```bash
make k3s
```

5. Install Argo CD

```bash
make argocd
```

6. Verify deployment

```bash
make verify
```

Or run all major phases:

```bash
make deploy
```

## Make Targets

- `make install-deps`
- `make bootstrap`
- `make k3s`
- `make argocd`
- `make verify`
- `make ping`
- `make deploy`

With custom inventory:

```bash
make k3s INVENTORY=path/to/hosts.yml
```

## SSH Key Migration and Hardening

Migrate selected hosts to key auth:

```bash
make ssh-key-only HOSTS=master-node_01
```

Direct playbook run with explicit target group:

```bash
ansible-playbook -i inventories/dev/hosts.yml playbooks/ssh_key_only.yml -e "target_hosts=master_node"
```

Enforce key-only SSH (disable password auth):

```bash
ansible-playbook -i inventories/dev/hosts.yml playbooks/ssh_key_only.yml -e "target_hosts=master_node disable_password_auth=true"
```

## Cluster Checks

Node status:

```bash
ansible -i inventories/dev/hosts.yml master_node -m shell -a "sudo k3s kubectl get nodes -o wide"
```

All pods:

```bash
ansible -i inventories/dev/hosts.yml master_node -m shell -a "sudo k3s kubectl get pods -A"
```

## Accessing from Lens

1. Create kubeconfig file from master:

```bash
ssh -t homelab@k3s-acer-f5-master.local "sudo cat /etc/rancher/k3s/k3s.yaml" > k3s_acer.yaml
```

2. Ensure kubeconfig `server:` points to a reachable host/IP from your machine.

3. Validate locally before importing to Lens:

```bash
kubectl --kubeconfig ./k3s_acer.yaml cluster-info
kubectl --kubeconfig ./k3s_acer.yaml get nodes
```

4. Import `k3s_acer.yaml` into Lens.

## Troubleshooting

- If Ansible warns about invalid group names, use underscore groups (already applied: `master_node`, `worker_node`).
- If a play seems stuck during K3s agent join, check:
	- worker service logs: `journalctl -u k3s-agent -n 100 --no-pager`
	- API reachability from worker to master `:6443`
- If Lens fails but `kubectl --kubeconfig ...` works, issue is Lens/client-side cache/proxy, not cluster health.

