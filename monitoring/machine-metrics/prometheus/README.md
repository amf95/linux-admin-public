# Info:
#### **Author**: Ahmed Fawzy (Github: amf95).

#### **Target**: `linux-amd64` with `systemd`.

#### **Purpose**: This script automates the installation of Prometheus on Linux/systemd systems.

#### **Tested On**: Ubuntu 24.04 server.

---
# Download Script:
```bash
curl --progress-bar -L -o "install-prometheus.sh" https://raw.githubusercontent.com/amf95/linux-admin-public/refs/heads/main/install-prometheus.sh
```

---
# Features and Usage:

- **Allow user to choose port during installation (default is 9090).**

- **Install Prometheus latest version from `GitHub` releases or a specific version:**
```bash
bash ./install-prometheus.sh
```

> Press Enter for latest version or enter specific one like: `3.7.2`.

- **Install from a local tar.gz file provided by the user:**
```bash
bash ./install-prometheus.sh --local prometheus-3.7.3.linux-amd64.tar.gz
```

> **Note: The local file must match the pattern `prometheus-X.Y.Z.linux-amd64.tar.gz` where X.Y.Z is the version number.**

- **Uninstall Prometheus while keeping data:**
```bash
bash ./install-prometheus.sh --uninstall
```

> **Note: The script offers to backup existing installation before uninstalling.**

- Purge Prometheus installation and wipe all data:
```bash
bash ./install-prometheus.sh --purge
```

> Note: The script offers to backup existing installation before purge.
