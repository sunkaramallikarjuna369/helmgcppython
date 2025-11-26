# Complete Helm Charts Guide

This guide provides detailed explanations of all Helm chart concepts, templates, and how everything works together in this project.

---

## Table of Contents

1. [What is Helm?](#what-is-helm)
2. [Chart Structure](#chart-structure)
3. [Chart.yaml Explained](#chartyaml-explained)
4. [Values Files Explained](#values-files-explained)
5. [Templates Explained](#templates-explained)
6. [How It All Works Together](#how-it-all-works-together)
7. [Helm Commands Reference](#helm-commands-reference)

---

## What is Helm?

**Helm** is a package manager for Kubernetes, like apt/yum for Linux or npm for Node.js.

### Why Use Helm?

**Without Helm:**
- You need to manage multiple YAML files manually
- Hard to reuse configurations across environments
- Difficult to version and share applications
- No easy way to upgrade/rollback

**With Helm:**
- Package all Kubernetes resources into a single "chart"
- Reuse the same chart for dev, preprod, and prod
- Easy upgrades and rollbacks
- Share charts via repositories

### Key Concepts

**Chart**: A package containing all Kubernetes resource definitions
**Release**: An instance of a chart running in a Kubernetes cluster
**Values**: Configuration parameters that customize a chart
**Template**: Kubernetes YAML files with placeholders for values

---

## Chart Structure

Our Helm chart is organized like this:

```
charts/platform/
├── Chart.yaml              # Chart metadata and dependencies
├── values.yaml             # Default values for all environments
├── values-dev.yaml         # Dev environment overrides
├── values-preprod.yaml     # Preprod environment overrides
├── values-prod.yaml        # Prod environment overrides
└── templates/              # Kubernetes resource templates
    ├── secret-db.yaml      # Database credentials secret
    ├── app-configmap.yaml  # Application code configmap
    ├── app-deployment.yaml # Application deployment
    └── app-service.yaml    # Application service
```

### Why This Structure?

1. **Chart.yaml**: Defines what the chart is and what it depends on
2. **values.yaml**: Default settings that work for all environments
3. **values-{env}.yaml**: Environment-specific overrides (passwords, resources, etc.)
4. **templates/**: Actual Kubernetes resources with templating

---

## Chart.yaml Explained

The `Chart.yaml` file is the metadata file for your Helm chart.

### Our Chart.yaml

```yaml
apiVersion: v2
name: platform
description: Simple PostgreSQL + Python FastAPI platform for dev/preprod/prod environments
type: application
version: 1.0.0
appVersion: "1.0"

# Dependency on Bitnami PostgreSQL chart
# This provides a production-ready PostgreSQL StatefulSet with PersistentVolume
dependencies:
  - name: postgresql
    version: 15.5.32
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
```

### Field Explanations

#### apiVersion: v2
- **What**: Helm chart API version
- **Why**: v2 is the current standard (supports dependencies)
- **When**: Always use v2 for new charts

#### name: platform
- **What**: The name of your chart
- **Why**: Used to identify the chart in Helm commands
- **Example**: `helm install my-release platform/`

#### description
- **What**: Human-readable description
- **Why**: Helps others understand what the chart does
- **Where**: Shows up in `helm search` results

#### type: application
- **What**: Type of chart
- **Options**: 
  - `application`: Deploys an application (our case)
  - `library`: Provides utilities for other charts
- **Why**: Tells Helm how to handle the chart

#### version: 1.0.0
- **What**: Chart version (not application version)
- **Why**: Track changes to the chart itself
- **When to change**: When you modify chart templates or structure
- **Format**: Semantic versioning (MAJOR.MINOR.PATCH)

#### appVersion: "1.0"
- **What**: Version of the application being deployed
- **Why**: Track which version of your app is in the chart
- **When to change**: When you update your application code
- **Note**: This is informational only

### Dependencies Section

This is the most important part for our setup!

```yaml
dependencies:
  - name: postgresql
    version: 15.5.32
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
```

#### What Are Dependencies?

Dependencies let you include other Helm charts inside your chart. Think of it like importing a library in code.

#### Our PostgreSQL Dependency

**name: postgresql**
- The name of the dependency chart
- We can reference it in templates as `.Values.postgresql`

**version: 15.5.32**
- Specific version of the Bitnami PostgreSQL chart
- **Why specific version?**: Ensures consistency across deployments
- **How to update**: Change version and run `helm dependency update`

**repository: https://charts.bitnami.com/bitnami**
- Where to download the chart from
- Bitnami provides production-ready charts

**condition: postgresql.enabled**
- Only install PostgreSQL if `postgresql.enabled=true` in values
- **Why**: Allows disabling PostgreSQL if using external database

#### What Does This Dependency Give Us?

The Bitnami PostgreSQL chart provides:
- ✅ PostgreSQL StatefulSet (persistent database)
- ✅ PersistentVolumeClaim (data storage)
- ✅ Service (network access)
- ✅ ConfigMap (PostgreSQL configuration)
- ✅ Health checks and probes
- ✅ Resource limits
- ✅ Security contexts

**Without this dependency**, we would need to write all these resources ourselves (hundreds of lines of YAML)!

#### How to Use Dependencies

**1. Add dependency to Chart.yaml** (already done)

**2. Update dependencies:**
```bash
helm dependency update charts/platform
```

This downloads the PostgreSQL chart to `charts/platform/charts/postgresql-15.5.32.tgz`

**3. Configure the dependency in values.yaml:**
```yaml
postgresql:
  enabled: true
  auth:
    existingSecret: "my-db-secret"
  primary:
    resources:
      requests:
        cpu: 100m
        memory: 256Mi
```

**4. Deploy:**
```bash
helm install my-release charts/platform
```

Both your app AND PostgreSQL get deployed!

---

## Values Files Explained

Values files contain configuration parameters that customize your Helm chart.

### The Values Hierarchy

Helm merges values from multiple sources in this order (later overrides earlier):

1. **values.yaml** (default values)
2. **values-{env}.yaml** (environment-specific)
3. **--set flags** (command-line overrides)

### values.yaml (Default Values)

This file contains settings that work for ALL environments.

```yaml
# Application settings
app:
  name: python-app
  replicaCount: 1
  image:
    repository: tiangolo/uvicorn-gunicorn-fastapi
    tag: python3.11-slim
    pullPolicy: IfNotPresent
  
  resources:
    requests:
      cpu: 50m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 256Mi
  
  service:
    type: ClusterIP
    port: 8000

# Database credentials (will be overridden per environment)
database:
  name: appdb
  username: appuser
  password: changeme123

# PostgreSQL configuration (Bitnami chart)
postgresql:
  enabled: true
  auth:
    existingSecret: "{{ .Release.Name }}-db-secret"
    secretKeys:
      adminPasswordKey: postgres-password
      userPasswordKey: password
      replicationPasswordKey: replication-password
  
  primary:
    resources:
      requests:
        cpu: 100m
        memory: 256Mi
      limits:
        cpu: 500m
        memory: 512Mi
    
    persistence:
      enabled: true
      storageClass: "standard-rwo"
      size: 5Gi
```

#### Section Breakdown

**app.name**
- **What**: Name of your application
- **Where used**: Labels, selectors, resource names
- **Example**: `{{ .Values.app.name }}` becomes `python-app`

**app.replicaCount**
- **What**: Number of application pods to run
- **Why**: More replicas = higher availability
- **Cost**: Each replica uses resources
- **Default**: 1 (sufficient for dev/preprod)

**app.image**
- **What**: Docker image to use
- **repository**: Image name (without tag)
- **tag**: Image version
- **pullPolicy**: When to pull the image
  - `IfNotPresent`: Only pull if not cached (default)
  - `Always`: Always pull latest
  - `Never`: Never pull, use cached only

**app.resources**
- **What**: CPU and memory limits
- **requests**: Minimum resources guaranteed
- **limits**: Maximum resources allowed
- **Why**: Prevents one pod from using all cluster resources

**CPU Units:**
- `1000m` = 1 CPU core
- `100m` = 0.1 CPU core (10% of one core)
- `50m` = 0.05 CPU core (5% of one core)

**Memory Units:**
- `1Gi` = 1 Gibibyte (1024 MiB)
- `256Mi` = 256 Mebibytes
- `128Mi` = 128 Mebibytes

**app.service.type**
- **ClusterIP**: Internal only (no external access)
  - **Cost**: FREE
  - **Access**: kubectl port-forward
- **LoadBalancer**: External access via cloud load balancer
  - **Cost**: ~$18-25/month
  - **Access**: Public IP address
- **NodePort**: External access via node IP
  - **Cost**: FREE
  - **Access**: Node IP + port

**database section**
- **What**: Database connection details
- **Why separate**: Each environment has different passwords
- **Overridden**: In values-dev.yaml, values-preprod.yaml, values-prod.yaml

**postgresql section**
- **What**: Configuration for Bitnami PostgreSQL chart
- **enabled**: Whether to install PostgreSQL
- **auth.existingSecret**: Use our custom secret for passwords
- **primary.resources**: CPU/memory for PostgreSQL
- **primary.persistence**: Storage configuration

**Storage Classes:**
- `standard-rwo`: Standard persistent disk (cheapest)
  - **Cost**: ~$0.04/GB/month
  - **Performance**: Good for most workloads
- `premium-rwo`: SSD persistent disk (faster)
  - **Cost**: ~$0.17/GB/month
  - **Performance**: High IOPS

### values-dev.yaml (Dev Environment)

Overrides for development environment:

```yaml
# Development environment values
# Override default values for dev environment

app:
  replicaCount: 1  # Single replica for dev

database:
  name: devdb
  username: devuser
  password: dev_password_123

postgresql:
  primary:
    resources:
      requests:
        cpu: 100m
        memory: 256Mi
    persistence:
      size: 5Gi  # Small storage for dev
```

#### What Gets Overridden?

- **database.name**: `devdb` instead of `appdb`
- **database.username**: `devuser` instead of `appuser`
- **database.password**: `dev_password_123` instead of `changeme123`
- **postgresql.primary.persistence.size**: Stays 5Gi (same as default)

#### What Stays the Same?

Everything not specified here uses values from `values.yaml`:
- app.image
- app.service.type
- app.resources
- postgresql.enabled
- etc.

### values-preprod.yaml (Preprod Environment)

```yaml
# Preprod environment values

app:
  replicaCount: 1  # Single replica for preprod

database:
  name: preproddb
  username: preproduser
  password: preprod_password_456

postgresql:
  primary:
    resources:
      requests:
        cpu: 150m
        memory: 384Mi
    persistence:
      size: 8Gi  # Slightly larger for preprod
```

#### Key Differences from Dev

- **More CPU**: 150m vs 100m (50% more)
- **More memory**: 384Mi vs 256Mi (50% more)
- **More storage**: 8Gi vs 5Gi (60% more)
- **Why**: Preprod should be closer to prod for testing

### values-prod.yaml (Prod Environment)

```yaml
# Production environment values

app:
  replicaCount: 2  # Two replicas for prod availability

database:
  name: proddb
  username: produser
  password: prod_password_789_CHANGE_THIS

postgresql:
  primary:
    resources:
      requests:
        cpu: 250m
        memory: 512Mi
      limits:
        cpu: 1000m
        memory: 1Gi
    persistence:
      size: 10Gi  # Larger storage for prod
```

#### Key Differences from Dev/Preprod

- **More replicas**: 2 vs 1 (high availability)
- **More CPU**: 250m vs 100m (2.5x more)
- **More memory**: 512Mi vs 256Mi (2x more)
- **Higher limits**: 1000m CPU, 1Gi memory
- **More storage**: 10Gi vs 5Gi (2x more)
- **Why**: Production needs reliability and performance

### How to Use Values Files

**Deploy to dev:**
```bash
helm install platform-dev charts/platform \
  --namespace dev \
  --values charts/platform/values-dev.yaml
```

**Deploy to preprod:**
```bash
helm install platform-preprod charts/platform \
  --namespace preprod \
  --values charts/platform/values-preprod.yaml
```

**Deploy to prod:**
```bash
helm install platform-prod charts/platform \
  --namespace prod \
  --values charts/platform/values-prod.yaml
```

**Override a specific value:**
```bash
helm install platform-dev charts/platform \
  --namespace dev \
  --values charts/platform/values-dev.yaml \
  --set app.replicaCount=3
```

---

## Templates Explained

Templates are Kubernetes YAML files with Helm templating syntax. They use values from `values.yaml` to generate actual Kubernetes resources.

### Template Syntax Basics

**Access a value:**
```yaml
{{ .Values.app.name }}
```

**Access release name:**
```yaml
{{ .Release.Name }}
```

**Access namespace:**
```yaml
{{ .Release.Namespace }}
```

**Conditional:**
```yaml
{{- if .Values.postgresql.enabled }}
  # This only appears if postgresql.enabled is true
{{- end }}
```

**Loop:**
```yaml
{{- range .Values.environments }}
  - {{ . }}
{{- end }}
```

### secret-db.yaml (Database Secret)

This template creates a Kubernetes Secret containing database credentials.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Release.Name }}-db-secret
  labels:
    app: {{ .Values.app.name }}
    release: {{ .Release.Name }}
type: Opaque
stringData:
  # PostgreSQL admin password
  postgres-password: {{ .Values.database.password }}
  # Application user password
  password: {{ .Values.database.password }}
  # Replication password (required by Bitnami chart)
  replication-password: {{ .Values.database.password }}
  # Database connection details for the application
  database-name: {{ .Values.database.name }}
  database-username: {{ .Values.database.username }}
```

#### What is a Kubernetes Secret?

A Secret stores sensitive data like passwords, tokens, and keys.

**Why use Secrets?**
- ✅ Encrypted at rest (in etcd)
- ✅ Not visible in pod specs
- ✅ Can be mounted as files or environment variables
- ✅ Access controlled by RBAC

#### Field Explanations

**metadata.name: {{ .Release.Name }}-db-secret**
- **What**: Name of the secret
- **Example**: If release name is `platform-dev`, secret name is `platform-dev-db-secret`
- **Why dynamic**: Allows multiple releases in same namespace

**labels**
- **What**: Key-value pairs for organizing resources
- **app**: Application name (for filtering)
- **release**: Release name (for tracking)
- **Usage**: `kubectl get secrets -l app=python-app`

**type: Opaque**
- **What**: Generic secret type
- **Other types**: `kubernetes.io/tls`, `kubernetes.io/dockerconfigjson`, etc.
- **Why Opaque**: For arbitrary key-value data

**stringData vs data**
- **stringData**: Plain text (Kubernetes encodes to base64)
- **data**: Base64-encoded (you encode manually)
- **Why stringData**: Easier to read and maintain

#### Secret Keys Explained

**postgres-password**
- **Used by**: PostgreSQL admin user (postgres)
- **Why**: Bitnami chart requires this key name

**password**
- **Used by**: Application database user
- **Why**: Bitnami chart requires this key name

**replication-password**
- **Used by**: PostgreSQL replication (if enabled)
- **Why**: Bitnami chart requires this key name

**database-name, database-username**
- **Used by**: Application to connect to database
- **Why**: Convenient for application configuration

#### How the Secret is Used

**By PostgreSQL (Bitnami chart):**
```yaml
postgresql:
  auth:
    existingSecret: "{{ .Release.Name }}-db-secret"
    secretKeys:
      adminPasswordKey: postgres-password
      userPasswordKey: password
```

**By Application:**
```yaml
env:
- name: DB_NAME
  valueFrom:
    secretKeyRef:
      name: platform-dev-db-secret
      key: database-name
```

### app-configmap.yaml (Application Code)

This template creates a ConfigMap containing the Python FastAPI application code.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-app-code
  labels:
    app: {{ .Values.app.name }}
    release: {{ .Release.Name }}
data:
  main.py: |
    from fastapi import FastAPI, HTTPException
    from pydantic import BaseModel
    import psycopg2
    import os
    
    # ... (full Python application code)
  
  requirements.txt: |
    fastapi==0.104.1
    uvicorn==0.24.0
    psycopg2-binary==2.9.9
    pydantic==2.5.0
```

#### What is a Kubernetes ConfigMap?

A ConfigMap stores non-sensitive configuration data.

**ConfigMap vs Secret:**
- **ConfigMap**: Non-sensitive data (code, config files)
- **Secret**: Sensitive data (passwords, tokens)

**Why use ConfigMap for code?**
- ✅ No need to build Docker images
- ✅ Easy to update (just helm upgrade)
- ✅ Version controlled with chart
- ❌ Not suitable for large applications (use images instead)

#### Field Explanations

**data.main.py**
- **What**: Python application code
- **Format**: Multi-line string (using `|`)
- **Mounted as**: `/app/main.py` in container

**data.requirements.txt**
- **What**: Python dependencies
- **Format**: Multi-line string
- **Mounted as**: `/app/requirements.txt` in container

#### How the ConfigMap is Used

In the Deployment:

```yaml
volumes:
- name: app-code
  configMap:
    name: {{ .Release.Name }}-app-code

volumeMounts:
- name: app-code
  mountPath: /app
  readOnly: true
```

This mounts the ConfigMap files into the container at `/app/`.

### app-deployment.yaml (Application Deployment)

This template creates a Kubernetes Deployment for the Python application.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-app
  labels:
    app: {{ .Values.app.name }}
    release: {{ .Release.Name }}
spec:
  replicas: {{ .Values.app.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Values.app.name }}
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Values.app.name }}
        release: {{ .Release.Name }}
    spec:
      containers:
      - name: app
        image: "{{ .Values.app.image.repository }}:{{ .Values.app.image.tag }}"
        imagePullPolicy: {{ .Values.app.image.pullPolicy }}
        ports:
        - containerPort: 8000
          name: http
        env:
        # Environment identifier
        - name: ENVIRONMENT
          value: "{{ .Release.Namespace }}"
        # Database connection details from secret
        - name: DB_HOST
          value: "{{ .Release.Name }}-postgresql"
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          valueFrom:
            secretKeyRef:
              name: {{ .Release.Name }}-db-secret
              key: database-name
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: {{ .Release.Name }}-db-secret
              key: database-username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ .Release.Name }}-db-secret
              key: password
        resources:
          {{- toYaml .Values.app.resources | nindent 10 }}
        livenessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
        volumeMounts:
        - name: app-code
          mountPath: /app
          readOnly: true
      volumes:
      - name: app-code
        configMap:
          name: {{ .Release.Name }}-app-code
```

#### What is a Kubernetes Deployment?

A Deployment manages a set of identical pods and ensures they're running.

**Key features:**
- ✅ Maintains desired number of replicas
- ✅ Rolling updates (zero downtime)
- ✅ Rollback capability
- ✅ Self-healing (restarts failed pods)

#### Field Explanations

**spec.replicas**
- **What**: Number of pod copies to run
- **Value**: `{{ .Values.app.replicaCount }}`
- **Dev**: 1 replica
- **Prod**: 2 replicas (high availability)

**spec.selector.matchLabels**
- **What**: How Deployment finds its pods
- **Must match**: template.metadata.labels
- **Why**: Allows Deployment to manage the right pods

**spec.template**
- **What**: Pod template (blueprint for pods)
- **Contains**: Container specs, volumes, etc.

**containers[0].image**
- **What**: Docker image to run
- **Value**: `tiangolo/uvicorn-gunicorn-fastapi:python3.11-slim`
- **Why this image**: Pre-configured FastAPI server

**containers[0].ports**
- **containerPort**: Port the app listens on (8000)
- **name**: Friendly name for the port (http)

**containers[0].env**
- **What**: Environment variables for the container
- **ENVIRONMENT**: Current namespace (dev/preprod/prod)
- **DB_HOST**: PostgreSQL service name
- **DB_PORT**: PostgreSQL port (5432)
- **DB_NAME, DB_USER, DB_PASSWORD**: From secret

**Environment Variables from Secret:**
```yaml
- name: DB_NAME
  valueFrom:
    secretKeyRef:
      name: platform-dev-db-secret
      key: database-name
```

This reads the `database-name` key from the secret and sets it as `DB_NAME` environment variable.

**containers[0].resources**
- **What**: CPU and memory limits
- **Value**: `{{- toYaml .Values.app.resources | nindent 10 }}`
- **toYaml**: Converts values to YAML
- **nindent 10**: Indents 10 spaces

**containers[0].livenessProbe**
- **What**: Checks if container is alive
- **Action**: Restarts container if check fails
- **httpGet**: Makes HTTP request to /health
- **initialDelaySeconds**: Wait 30s before first check
- **periodSeconds**: Check every 10s

**containers[0].readinessProbe**
- **What**: Checks if container is ready for traffic
- **Action**: Removes from service if check fails
- **httpGet**: Makes HTTP request to /health
- **initialDelaySeconds**: Wait 5s before first check
- **periodSeconds**: Check every 5s

**Liveness vs Readiness:**
- **Liveness**: Is the app running? (restart if not)
- **Readiness**: Is the app ready for traffic? (don't send traffic if not)

**containers[0].volumeMounts**
- **What**: Mounts volumes into container
- **name**: Volume name (must match volumes[])
- **mountPath**: Where to mount in container (/app)
- **readOnly**: Prevent modifications

**volumes**
- **What**: Defines volumes available to pod
- **configMap**: Mount ConfigMap as volume
- **name**: Volume name (referenced in volumeMounts)

### app-service.yaml (Application Service)

This template creates a Kubernetes Service for the application.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-app
  labels:
    app: {{ .Values.app.name }}
    release: {{ .Release.Name }}
spec:
  type: {{ .Values.app.service.type }}
  ports:
  - port: {{ .Values.app.service.port }}
    targetPort: http
    protocol: TCP
    name: http
  selector:
    app: {{ .Values.app.name }}
    release: {{ .Release.Name }}
```

#### What is a Kubernetes Service?

A Service provides stable networking for pods.

**Why needed?**
- Pods have dynamic IPs (change on restart)
- Service provides stable DNS name
- Load balances across multiple pods

**Service Types:**
- **ClusterIP**: Internal only (default)
- **NodePort**: Accessible via node IP
- **LoadBalancer**: Cloud load balancer (costs money)

#### Field Explanations

**spec.type**
- **Value**: `{{ .Values.app.service.type }}`
- **Default**: ClusterIP (internal only)
- **Why**: Saves money (no load balancer costs)

**spec.ports**
- **port**: Service port (8000)
- **targetPort**: Container port (http = 8000)
- **protocol**: TCP
- **name**: Port name (http)

**spec.selector**
- **What**: Selects pods to route traffic to
- **Must match**: Deployment pod labels
- **Example**: Routes to pods with `app=python-app` and `release=platform-dev`

#### How Service Works

1. **Client** makes request to `platform-dev-app:8000`
2. **Service** finds pods matching selector
3. **Service** load balances request to one pod
4. **Pod** receives request on port 8000

**DNS Names:**
- Within namespace: `platform-dev-app`
- Cross-namespace: `platform-dev-app.dev.svc.cluster.local`
- From outside: Use `kubectl port-forward`

---

## How It All Works Together

Let's trace a complete deployment from start to finish.

### Step 1: Helm Install Command

```bash
helm install platform-dev charts/platform \
  --namespace dev \
  --values charts/platform/values-dev.yaml
```

### Step 2: Helm Processes Chart

1. **Reads Chart.yaml**
   - Sees PostgreSQL dependency
   - Loads PostgreSQL chart from charts/ directory

2. **Merges Values**
   - Starts with values.yaml (defaults)
   - Overlays values-dev.yaml (dev overrides)
   - Final values used for templating

3. **Renders Templates**
   - Replaces `{{ .Values.app.name }}` with `python-app`
   - Replaces `{{ .Release.Name }}` with `platform-dev`
   - Replaces `{{ .Release.Namespace }}` with `dev`
   - Generates actual Kubernetes YAML

### Step 3: Resources Created

**Order of creation:**

1. **Namespace** (if doesn't exist)
   ```bash
   kubectl create namespace dev
   ```

2. **Secret** (secret-db.yaml)
   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: platform-dev-db-secret
   stringData:
     postgres-password: dev_password_123
     password: dev_password_123
     database-name: devdb
     database-username: devuser
   ```

3. **ConfigMap** (app-configmap.yaml)
   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: platform-dev-app-code
   data:
     main.py: |
       # Python code here
   ```

4. **PostgreSQL Resources** (from Bitnami chart)
   - PersistentVolumeClaim (5Gi storage)
   - StatefulSet (PostgreSQL pod)
   - Service (postgresql:5432)
   - ConfigMap (PostgreSQL config)

5. **Application Deployment** (app-deployment.yaml)
   - Creates 1 pod (dev) or 2 pods (prod)
   - Mounts ConfigMap as /app
   - Sets environment variables from Secret

6. **Application Service** (app-service.yaml)
   - Creates ClusterIP service
   - Routes traffic to application pods

### Step 4: Pods Start

**PostgreSQL Pod:**
1. PersistentVolume provisioned (5Gi disk)
2. PostgreSQL container starts
3. Reads password from Secret
4. Initializes database
5. Creates `devdb` database
6. Creates `devuser` user
7. Readiness probe passes
8. Pod marked Ready

**Application Pod:**
1. Pulls image: `tiangolo/uvicorn-gunicorn-fastapi:python3.11-slim`
2. Mounts ConfigMap to /app
3. Installs dependencies from requirements.txt
4. Starts FastAPI application
5. Connects to PostgreSQL using environment variables
6. Liveness probe passes (GET /health)
7. Readiness probe passes
8. Pod marked Ready

### Step 5: Service Routes Traffic

**Service DNS:**
- `platform-dev-app.dev.svc.cluster.local`
- Short name: `platform-dev-app` (within namespace)

**Traffic flow:**
```
kubectl port-forward → Service → Pod(s) → FastAPI app → PostgreSQL
```

### Step 6: Application Runs

**Application can:**
- Accept HTTP requests on port 8000
- Connect to PostgreSQL at `platform-dev-postgresql:5432`
- Read database credentials from environment variables
- Store data in PostgreSQL (persisted to disk)

### Step 7: Accessing the Application

**From local machine:**
```bash
kubectl port-forward -n dev svc/platform-dev-app 8000:8000
curl http://localhost:8000/health
```

**From another pod in cluster:**
```bash
curl http://platform-dev-app:8000/health
```

### Step 8: Updating the Application

**Change values:**
```bash
helm upgrade platform-dev charts/platform \
  --namespace dev \
  --values charts/platform/values-dev.yaml \
  --set app.replicaCount=2
```

**What happens:**
1. Helm compares current state with desired state
2. Updates Deployment with new replica count
3. Kubernetes creates additional pod
4. Service automatically routes to both pods
5. Zero downtime (rolling update)

### Step 9: Rollback (if needed)

**View history:**
```bash
helm history platform-dev -n dev
```

**Rollback to previous version:**
```bash
helm rollback platform-dev -n dev
```

**What happens:**
1. Helm restores previous configuration
2. Kubernetes updates resources
3. Application returns to previous state

---

## Helm Commands Reference

### Installation

**Install chart:**
```bash
helm install RELEASE_NAME CHART_PATH \
  --namespace NAMESPACE \
  --values VALUES_FILE
```

**Example:**
```bash
helm install platform-dev charts/platform \
  --namespace dev \
  --values charts/platform/values-dev.yaml
```

**Install with overrides:**
```bash
helm install platform-dev charts/platform \
  --namespace dev \
  --values charts/platform/values-dev.yaml \
  --set app.replicaCount=3 \
  --set database.password=newsecret
```

### Upgrades

**Upgrade release:**
```bash
helm upgrade RELEASE_NAME CHART_PATH \
  --namespace NAMESPACE \
  --values VALUES_FILE
```

**Upgrade with new values:**
```bash
helm upgrade platform-dev charts/platform \
  --namespace dev \
  --values charts/platform/values-dev.yaml \
  --set app.image.tag=v2.0
```

### Viewing

**List releases:**
```bash
helm list -n NAMESPACE
```

**Get release details:**
```bash
helm get all RELEASE_NAME -n NAMESPACE
```

**Get values:**
```bash
helm get values RELEASE_NAME -n NAMESPACE
```

**View history:**
```bash
helm history RELEASE_NAME -n NAMESPACE
```

### Testing

**Dry run (don't install):**
```bash
helm install platform-dev charts/platform \
  --namespace dev \
  --values charts/platform/values-dev.yaml \
  --dry-run
```

**Template (render without installing):**
```bash
helm template platform-dev charts/platform \
  --namespace dev \
  --values charts/platform/values-dev.yaml
```

**Debug:**
```bash
helm install platform-dev charts/platform \
  --namespace dev \
  --values charts/platform/values-dev.yaml \
  --debug
```

### Rollback

**Rollback to previous:**
```bash
helm rollback RELEASE_NAME -n NAMESPACE
```

**Rollback to specific revision:**
```bash
helm rollback RELEASE_NAME REVISION -n NAMESPACE
```

**Example:**
```bash
helm rollback platform-dev 2 -n dev
```

### Uninstallation

**Uninstall release:**
```bash
helm uninstall RELEASE_NAME -n NAMESPACE
```

**Keep history:**
```bash
helm uninstall RELEASE_NAME -n NAMESPACE --keep-history
```

### Dependencies

**Update dependencies:**
```bash
cd charts/platform
helm dependency update
```

**List dependencies:**
```bash
helm dependency list
```

**Build dependencies:**
```bash
helm dependency build
```

---

## Summary

### Key Takeaways

1. **Helm** packages Kubernetes resources into reusable charts
2. **Chart.yaml** defines metadata and dependencies
3. **values.yaml** provides default configuration
4. **values-{env}.yaml** override defaults per environment
5. **Templates** generate Kubernetes resources using values
6. **Dependencies** let you include other charts (like PostgreSQL)
7. **Secrets** store sensitive data (passwords)
8. **ConfigMaps** store non-sensitive data (code, config)
9. **Deployments** manage application pods
10. **Services** provide stable networking

### Best Practices

✅ **Use dependencies** instead of writing everything yourself
✅ **Separate values** per environment
✅ **Use Secrets** for passwords
✅ **Use ConfigMaps** for configuration
✅ **Set resource limits** to prevent resource exhaustion
✅ **Use health probes** for reliability
✅ **Use ClusterIP** services to save money
✅ **Version your charts** with semantic versioning
✅ **Test with dry-run** before deploying
✅ **Keep backups** of PersistentVolumes

### Common Patterns

**Multi-environment deployment:**
```bash
# Dev
helm install platform-dev charts/platform -n dev -f values-dev.yaml

# Preprod
helm install platform-preprod charts/platform -n preprod -f values-preprod.yaml

# Prod
helm install platform-prod charts/platform -n prod -f values-prod.yaml
```

**Update application code:**
1. Edit ConfigMap in templates/app-configmap.yaml
2. Run `helm upgrade`
3. Restart pods: `kubectl rollout restart deployment/platform-dev-app -n dev`

**Scale application:**
```bash
helm upgrade platform-dev charts/platform -n dev \
  -f values-dev.yaml \
  --set app.replicaCount=3
```

**Change database password:**
1. Update values-{env}.yaml
2. Run `helm upgrade`
3. Restart pods to pick up new password

---

## Next Steps

1. **Read the main README.md** for quick start guide
2. **Follow WINDOWS-GUIDE.md** for step-by-step setup
3. **Explore the templates** in charts/platform/templates/
4. **Customize values** for your use case
5. **Deploy to your cluster** and test!

For questions or issues, refer to the troubleshooting section in README.md.
