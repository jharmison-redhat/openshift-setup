---
name: kubernetes-helm-config
description:
  "Hermes runs in Kubernetes with config.yaml mounted as a read-only ConfigMap. All config changes must be made via the
  Helm chart values file under the top-level 'config' key. This skill provides the correct workflow and outputs YAML
  diffs for Helm values updates."
version: 1.0.0
author: agent
license: MIT
metadata:
  hermes:
    tags: [kubernetes, helm, config, hermes, k8s, configmap]
---

# Kubernetes Helm Config Workflow

## Environment

Hermes Agent runs inside a Kubernetes cluster. The `config.yaml` file is **mounted from a ConfigMap as read-only**.
Direct edits to `config.yaml` (via `write_file`, `patch`, shell redirection, or `hermes config set`) will **fail** —
either with permission errors, device-busy errors, or atomic-rename failures.

## How to Change Configuration

All configuration changes must be applied through the **Helm chart values file**. The Hermes config lives nested under
the top-level `config` key in the Helm values, as a YAML dict.

### Process

1. **Identify the config change** the user wants to make.
2. **Show the current config** by reading `/opt/data/config.yaml`.
3. **Output the updated Helm values block** — the full `config:` section as it should appear in the Helm values file.
   Format it clearly as a YAML snippet.
4. **Instruct the user** to apply the change via `helm upgrade` or their Helm workflow.

### Output Format

When a config change is needed, always output a diff-style block showing:

```yaml
# Helm values — update the 'config' key with these changes:
config:
  model: ...
  auxiliary: ...
  # ... other sections ...
```

Highlight what changed and why.

### Common Config Paths

| What they want     | Helm values path            |
| ------------------ | --------------------------- |
| Main model         | `config.model.model`        |
| Model provider     | `config.model.provider`     |
| Model base URL     | `config.model.base_url`     |
| API key            | `config.model.api_key`      |
| Auxiliary model    | `config.auxiliary.model`    |
| Auxiliary provider | `config.auxiliary.provider` |
| Auxiliary base URL | `config.auxiliary.base_url` |
| Agent settings     | `config.agent.*`            |
| Terminal backend   | `config.terminal.backend`   |
| Compression        | `config.compression.*`      |
| Delegation         | `config.delegation.*`       |

### Pitfalls

- **Never attempt to write directly** to `/opt/data/config.yaml` — it is read-only in this environment.
- **`hermes config set` fails** with `OSError: [Errno 16] Device or resource busy` due to the ConfigMap mount.
- **`write_file` and `patch` tools are blocked** on `config.yaml` by the agent's security policy.
- **Changes take effect after the Helm upgrade** rolls out a new ConfigMap. The Helm upgrade restarts the pod
  automatically — no manual restart, `/restart`, or session relaunch is needed.

### Verification

After the user confirms the Helm upgrade, verify the config was applied by reading `/opt/data/config.yaml` and comparing
against the expected values.
