# Kubernetes Instructions

## Toolchain
- kubectl — primary CLI
- Helm — package manager
- kustomize — config management
- stern — log tailing (optional)

## Commands
```bash
# Context
kubectl config get-contexts
kubectl config use-context <name>

# Pods
kubectl get pods -A
kubectl logs -f deployment/<name>

# Config
kubectl apply -f manifest.yaml
kubectl diff -f manifest.yaml

# Helm
helm list -A
helm upgrade --install <release> <chart> -f values.yaml
helm template <release> <chart> --dry-run

# Debug
kubectl exec -it pod/<name> -- sh
kubectl port-forward svc/<name> 8080:80
```

## Conventions
- Use `kubectl diff` before apply
- Prefer Helm for complex deployments
- Use namespaces for isolation
- Labels: `app.kubernetes.io/name`, `app.kubernetes.io/component`
- Resource limits обязательны для production
- Use NetworkPolicies for zero-trust

## Verify
```bash
kubectl version --client && helm version
```
