# CI/CD Pipeline Guide

This guide explains how to use the comprehensive CI/CD pipeline we've set up for the CRUD Backend Application.

## 🏗️ Pipeline Overview

Our CI/CD pipeline consists of three main workflows:

### 1. **Continuous Integration (CI)** - `.github/workflows/ci.yml`
**Triggers**: Push to `main`/`develop`, Pull Requests
**Purpose**: Test, build, and validate code changes

### 2. **Continuous Deployment (CD)** - `.github/workflows/cd.yml` 
**Triggers**: Push to `production`, Manual dispatch
**Purpose**: Deploy to staging and production environments

### 3. **Dependency Updates** - `.github/workflows/dependency-update.yml`
**Triggers**: Weekly schedule, Manual dispatch  
**Purpose**: Automatically update dependencies and create PRs

## 🚀 How to Use the Pipeline

### For Feature Development

1. **Create Feature Branch**:
   ```bash
   git checkout main
   git pull origin main
   git checkout -b feature/awesome-new-feature
   ```

2. **Develop and Test Locally**:
   ```bash
   # Test with Docker Compose
   docker-compose up -d
   curl http://localhost:3000/healthz
   
   # Test with Kubernetes
   ./k8s/deploy.sh start
   ```

3. **Push and Create PR**:
   ```bash
   git add .
   git commit -m "feat: add awesome new feature"
   git push origin feature/awesome-new-feature
   # Create PR via GitHub UI
   ```

4. **CI Pipeline Runs Automatically**:
   - ✅ Linting (ESLint)
   - ✅ Tests (Unit + Integration)
   - ✅ Docker build
   - ✅ Security scanning
   - ✅ Code quality checks

### For Production Releases

1. **Merge to Main** (after PR approval):
   - Code is automatically deployed to staging
   - Staging tests run automatically

2. **Deploy to Production**:
   ```bash
   git checkout production
   git merge main
   git push origin production
   ```

3. **Production Pipeline Runs**:
   - ✅ Deploy to production with 5 replicas
   - ✅ Enable HPA (auto-scaling)
   - ✅ Run health checks
   - ✅ Create GitHub release
   - 🚨 Automatic rollback on failure

### Manual Deployment

You can trigger deployments manually via GitHub Actions:

1. Go to **Actions** tab in GitHub
2. Select **CD Pipeline**
3. Click **Run workflow**
4. Choose:
   - Environment: `staging` or `production`  
   - Image tag: `latest` or specific version

## 📊 Pipeline Features

### 🔒 Security & Quality

- **Vulnerability Scanning**: Trivy scans all Docker images
- **Code Quality**: SonarCloud integration (optional)
- **Secrets Detection**: No secrets allowed in code
- **Security Contexts**: Non-root containers
- **RBAC**: Kubernetes role-based access control

### 📈 Monitoring & Observability

- **Health Checks**: Built-in health endpoints
- **Kubernetes Probes**: Liveness and readiness probes
- **Resource Limits**: CPU and memory constraints
- **Metrics**: Prometheus-ready metrics endpoint

### 🔄 Auto-Scaling & High Availability

- **Horizontal Pod Autoscaler**: Auto-scale based on CPU/memory
- **Rolling Updates**: Zero-downtime deployments
- **Multiple Replicas**: 3 replicas in staging, 5 in production
- **Load Balancing**: Kubernetes services distribute traffic

### 🛡️ Reliability Features

- **Automatic Rollback**: Failed deployments auto-rollback
- **Health Checks**: Comprehensive health validation
- **Graceful Shutdowns**: Proper container lifecycle management
- **Persistent Storage**: Database data survives restarts

## 🎯 Environment Strategy

### **Staging Environment**
- **Purpose**: Integration testing and validation
- **Deployment**: Automatic on push to `main`
- **URL**: `https://crud-app-staging.example.com` (configure your actual URL)
- **Resources**: Lower resource allocation
- **Data**: Test data, can be reset

### **Production Environment** 
- **Purpose**: Live application serving users
- **Deployment**: Manual approval required
- **URL**: `https://crud-app.example.com` (configure your actual URL)
- **Resources**: Full resource allocation with HPA
- **Data**: Persistent, backed up

## 🔧 Configuration Required

To fully activate the pipeline, you'll need to configure these GitHub Secrets:

### Required Secrets

```bash
# Container Registry (automatically configured for GitHub)
GITHUB_TOKEN  # Automatically provided

# Optional: Cloud Provider (AWS example)
AWS_ACCESS_KEY_ID      # Your AWS access key
AWS_SECRET_ACCESS_KEY  # Your AWS secret key  
AWS_REGION             # e.g., us-west-2

# Optional: Kubernetes Clusters
KUBE_CONFIG_STAGING    # Base64 encoded kubeconfig for staging
KUBE_CONFIG_PRODUCTION # Base64 encoded kubeconfig for production

# Optional: Code Quality
SONAR_TOKEN           # SonarCloud token (if using)
```

### Setting up Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Add the required secrets listed above

## 🚀 Scaling Demonstrations

### Manual Scaling

Scale your application to test load handling:

```bash
# Scale to 10 replicas
kubectl scale deployment backend --replicas=10 -n crud-app

# Monitor scaling
kubectl get pods -n crud-app -w
```

### Auto-Scaling Test

Generate load to trigger HPA:

```bash
# Enable HPA
./k8s/deploy.sh hpa

# Run load test
./k8s/deploy.sh load-test

# Watch auto-scaling in action
kubectl get hpa -n crud-app -w
```

### Rolling Updates

Test zero-downtime deployments:

```bash
# Update the image tag
kubectl set image deployment/backend backend=ghcr.io/murangomike/cidemo:new-version -n crud-app

# Watch rolling update
kubectl rollout status deployment/backend -n crud-app

# Rollback if needed  
kubectl rollout undo deployment/backend -n crud-app
```

## 📈 Monitoring Your Pipeline

### GitHub Actions

- **Actions Tab**: View all pipeline runs
- **Workflow runs**: See detailed logs and status
- **Artifacts**: Download test results and reports

### Kubernetes Monitoring

```bash
# Check deployment status
kubectl get all -n crud-app

# View pod logs
kubectl logs -f deployment/backend -n crud-app

# Check HPA status
kubectl get hpa -n crud-app

# Monitor resource usage
kubectl top pods -n crud-app
```

### Application Monitoring

```bash
# Health check
curl https://your-app-url/healthz

# API endpoints
curl https://your-app-url/users

# Load testing
ab -n 1000 -c 10 https://your-app-url/users
```

## 🎓 Learning Opportunities

This pipeline demonstrates:

- **GitOps practices**: Infrastructure as code
- **Container orchestration**: Docker + Kubernetes  
- **CI/CD automation**: GitHub Actions
- **Security scanning**: Vulnerability detection
- **Auto-scaling**: Based on metrics
- **Zero-downtime deployments**: Rolling updates
- **Monitoring & observability**: Health checks and logs
- **Incident response**: Automatic rollbacks

## 🛠️ Customization

### Adding New Environments

1. Create new Kubernetes namespace
2. Add environment-specific secrets
3. Update CD pipeline with new deployment job
4. Configure environment-specific settings

### Adding Tests

1. Create test files in appropriate directories
2. Update CI pipeline to run new tests
3. Add test results to artifacts
4. Configure test coverage reporting

### Adding Monitoring

1. Deploy Prometheus and Grafana
2. Add metrics endpoints to application
3. Configure alerting rules
4. Set up notification channels

## 🔄 Next Steps

1. **Configure actual cloud environments** (AWS, GCP, Azure)
2. **Set up monitoring stack** (Prometheus, Grafana, AlertManager)
3. **Add more comprehensive tests** (E2E, load testing)
4. **Configure backup strategies** for database
5. **Set up log aggregation** (ELK stack or similar)
6. **Add more security scanning** (SAST, DAST tools)

This pipeline provides a solid foundation for modern DevOps practices! 🚀
