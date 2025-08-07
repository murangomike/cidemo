# Docker Hub Setup Guide

This guide explains how to configure Docker Hub integration for the CI/CD pipeline.

## 🐳 Docker Hub Configuration

### 1. Create Docker Hub Repository

1. Go to [Docker Hub](https://hub.docker.com/)
2. Sign in with your account (`murango001`)
3. Click "Create Repository"
4. Repository name: `ciddemo`
5. Set visibility (Public recommended for learning)
6. Click "Create"

Repository URL: `https://hub.docker.com/r/murango001/ciddemo`

### 2. Generate Access Token

1. Go to Docker Hub → Account Settings → Security
2. Click "New Access Token"
3. Name: `GitHub Actions CI/CD`
4. Permissions: `Read, Write, Delete`
5. Copy the generated token (save it securely!)

### 3. Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these repository secrets:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `DOCKERHUB_USERNAME` | `murango001` | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | `dckr_pat_xxxxx` | The access token from step 2 |

## 🚀 Using the CI/CD Pipeline

### Automatic Image Building

The pipeline automatically builds and pushes Docker images when you:

1. **Push to `main` branch**: Builds and pushes image with tags:
   - `murango001/ciddemo:latest`
   - `murango001/ciddemo:main`
   - `murango001/ciddemo:main-<commit-sha>`

2. **Push to `production` branch**: Builds and pushes:
   - `murango001/ciddemo:production`
   - Updates `latest` tag

### Manual Image Building

Use the Docker Hub management script for local operations:

```bash
# Build image locally
./scripts/docker-hub.sh build

# Build and push to Docker Hub
./scripts/docker-hub.sh build-push

# Create a release (build, tag, and push)
./scripts/docker-hub.sh release v1.0.0

# Test image locally
./scripts/docker-hub.sh test

# Login to Docker Hub
./scripts/docker-hub.sh login

# View help
./scripts/docker-hub.sh
```

## 📊 Image Tags Strategy

| Branch/Event | Tags Created | Usage |
|--------------|--------------|-------|
| `main` push | `latest`, `main`, `main-<sha>` | Development/Staging |
| `production` push | `production`, `latest` | Production |
| Manual release | `v1.0.0`, `latest` | Versioned releases |
| PR | `pr-<number>` | Pull request testing |

## 🔄 Deployment Workflow

### Staging Deployment
1. Merge PR to `main`
2. CI builds and pushes `murango001/ciddemo:main`
3. CD deploys to staging using `main` tag
4. Automated smoke tests run

### Production Deployment
1. Merge `main` to `production`
2. CI builds and pushes `murango001/ciddemo:production`
3. CD deploys to production with 5 replicas
4. Health checks and rollback on failure

## 🏗️ Kubernetes Integration

The Kubernetes manifests automatically use Docker Hub images:

```yaml
# k8s/backend.yaml
containers:
- name: backend
  image: murango001/ciddemo:latest
  imagePullPolicy: Always
```

Update image in running deployment:
```bash
# Update to specific version
kubectl set image deployment/backend backend=murango001/ciddemo:v1.0.0 -n crud-app

# Rollback to previous version
kubectl rollout undo deployment/backend -n crud-app
```

## 📈 Monitoring Images

### Docker Hub Dashboard
- View at: https://hub.docker.com/r/murango001/ciddemo
- See download statistics
- Manage tags and descriptions

### GitHub Actions
- View build logs in Actions tab
- Monitor image sizes and build times
- Check security scan results

### Local Commands
```bash
# List local images
docker images murango001/ciddemo

# Pull latest from Docker Hub
docker pull murango001/ciddemo:latest

# Check image details
docker inspect murango001/ciddemo:latest

# View image layers
docker history murango001/ciddemo:latest
```

## 🔒 Security Considerations

### Image Scanning
- Trivy automatically scans all images
- Results uploaded to GitHub Security tab
- Vulnerabilities reported in pipeline

### Access Control
- Docker Hub access token has limited permissions
- Token stored securely in GitHub Secrets
- Regular token rotation recommended

### Image Signing (Optional)
For production use, consider:
- Docker Content Trust
- Cosign for image signing
- SBOM (Software Bill of Materials) generation

## 🛠️ Troubleshooting

### Common Issues

**Authentication Failed**
```bash
Error: denied: requested access to the resource is denied
```
- Check DOCKERHUB_USERNAME and DOCKERHUB_TOKEN secrets
- Verify token has correct permissions
- Try manual login: `docker login`

**Image Not Found**
```bash
Error: pull access denied for murango001/ciddemo
```
- Check repository exists and is public
- Verify image tag exists
- Check network connectivity

**Build Failed**
- Check Dockerfile syntax
- Verify base image availability
- Review build logs in GitHub Actions

### Debug Commands

```bash
# Test Docker Hub connectivity
docker pull hello-world

# Check current Docker login
docker info | grep Username

# Verify image locally
./scripts/docker-hub.sh test

# Check Kubernetes deployment
kubectl describe deployment backend -n crud-app
```

## 📚 Additional Resources

- [Docker Hub Documentation](https://docs.docker.com/docker-hub/)
- [GitHub Actions Docker Guide](https://docs.github.com/en/actions/publishing-packages/publishing-docker-images)
- [Kubernetes Image Pull Policies](https://kubernetes.io/docs/concepts/containers/images/)
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)

## 🎯 Next Steps

1. **Set up the secrets** in GitHub repository settings
2. **Test the pipeline** by pushing to main branch
3. **Verify images** are pushed to Docker Hub
4. **Deploy to Kubernetes** using the new images
5. **Monitor and optimize** image sizes and build times

Your CI/CD pipeline is now configured to use Docker Hub for image storage and distribution! 🚀
