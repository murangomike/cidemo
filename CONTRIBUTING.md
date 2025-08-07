# Contributing to CRUD Backend Application

Thank you for your interest in contributing to our project! This document outlines the development workflow and guidelines for contributing.

## 🌟 Branch Strategy

We use a **GitFlow-inspired** branching strategy with the following branches:

### Main Branches

- **`main`**: Development branch where features are integrated and tested
  - Automatically triggers CI pipeline
  - Deploys to staging environment
  - Should always be stable and deployable

- **`production`**: Production-ready code
  - Only receives merges from `main` after thorough testing
  - Triggers production deployment pipeline
  - Protected branch requiring review and approvals

### Supporting Branches

- **`feature/[feature-name]`**: For new features
- **`bugfix/[bug-description]`**: For bug fixes
- **`hotfix/[critical-fix]`**: For urgent production fixes
- **`release/[version]`**: For preparing releases

## 🚀 Development Workflow

### 1. Setting Up Development Environment

```bash
# Clone the repository
git clone https://github.com/murangomike/cidemo.git
cd cidemo/backend

# Install dependencies
npm install

# Start development environment
docker-compose up -d

# Or use Kubernetes for testing
./k8s/deploy.sh start
```

### 2. Creating a New Feature

```bash
# Create and switch to feature branch from main
git checkout main
git pull origin main
git checkout -b feature/your-feature-name

# Make your changes
# ... code changes ...

# Test your changes
npm run lint
npm test
docker-compose up -d  # Test with Docker

# Commit your changes
git add .
git commit -m "feat: add new feature description"

# Push to remote
git push origin feature/your-feature-name

# Create Pull Request via GitHub UI
```

### 3. Pull Request Process

1. **Create PR**: Open a pull request from your feature branch to `main`
2. **Fill Template**: Complete the PR template with all required information
3. **Review**: Wait for code review and address feedback
4. **CI Checks**: Ensure all CI checks pass
5. **Approval**: Get at least one approval from a maintainer
6. **Merge**: Maintainer will merge using "Squash and merge"

### 4. Release Process

```bash
# Create release branch from main
git checkout main
git pull origin main
git checkout -b release/v1.2.0

# Update version numbers, changelog, etc.
# ... make release preparations ...

# Commit release preparations
git add .
git commit -m "chore: prepare release v1.2.0"

# Push release branch
git push origin release/v1.2.0

# Create PR to production
# After approval, merge to production
# This will trigger production deployment
```

### 5. Hotfix Process

```bash
# Create hotfix branch from production
git checkout production
git pull origin production
git checkout -b hotfix/critical-security-fix

# Make the critical fix
# ... fix the issue ...

# Test the fix thoroughly
npm test
docker-compose up -d

# Commit the fix
git add .
git commit -m "fix: resolve critical security vulnerability"

# Push hotfix branch
git push origin hotfix/critical-security-fix

# Create PR to production (expedited review)
# After merge, also merge back to main
```

## 📋 Code Standards

### Code Style

- **ESLint**: We use ESLint for code linting
- **Prettier**: Code formatting (if configured)
- **Naming**: Use descriptive variable and function names
- **Comments**: Add comments for complex logic

### Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `ci`: CI/CD changes

**Examples:**
```bash
git commit -m "feat: add user authentication endpoint"
git commit -m "fix: resolve database connection timeout issue"
git commit -m "docs: update API documentation for user endpoints"
git commit -m "chore: update dependencies to latest versions"
```

### Testing Requirements

- **Unit Tests**: Write unit tests for new functions
- **Integration Tests**: Test API endpoints thoroughly
- **Docker Tests**: Ensure application works in containers
- **Kubernetes Tests**: Verify K8s deployments work correctly

## 🏗️ CI/CD Pipeline

### Continuous Integration (CI)

**Triggered on**: Push to `main`, `develop`, or PRs

**Pipeline includes:**
1. Code linting (ESLint)
2. Unit and integration tests
3. Docker image build
4. Security scanning (Trivy)
5. Code quality checks (SonarCloud)

### Continuous Deployment (CD)

**Staging Deployment:**
- **Triggered**: Push to `main`
- **Environment**: Staging Kubernetes cluster
- **URL**: https://crud-app-staging.example.com

**Production Deployment:**
- **Triggered**: Push to `production`
- **Environment**: Production Kubernetes cluster  
- **URL**: https://crud-app.example.com
- **Requirements**: Manual approval, health checks

## 🔐 Security Guidelines

### Code Security

- **No Secrets**: Never commit passwords, API keys, or sensitive data
- **Environment Variables**: Use environment variables for configuration
- **Input Validation**: Always validate and sanitize user input
- **SQL Injection**: Use parameterized queries
- **Authentication**: Implement proper authentication and authorization

### Infrastructure Security

- **Docker Security**: Use non-root users in containers
- **Kubernetes Security**: Apply security contexts and network policies
- **Secrets Management**: Use Kubernetes secrets or external secret managers
- **Image Scanning**: All images are automatically scanned for vulnerabilities

## 🐛 Bug Reports and Feature Requests

### Reporting Bugs

1. Check existing issues to avoid duplicates
2. Use the bug report template
3. Include reproduction steps and environment details
4. Add relevant labels and assignees

### Requesting Features

1. Use the feature request template
2. Clearly describe the problem and proposed solution
3. Consider implementation impact and alternatives
4. Discuss with maintainers before starting work

## 📞 Getting Help

### Communication Channels

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For general questions and ideas
- **Pull Request Comments**: For code-specific discussions

### Code Review Guidelines

**For Authors:**
- Keep PRs small and focused
- Write clear descriptions and test instructions
- Respond to feedback promptly
- Ensure CI checks pass

**For Reviewers:**
- Be constructive and helpful in feedback
- Focus on code quality, security, and maintainability
- Test changes locally when possible
- Approve when satisfied with changes

## 📦 Release Management

### Versioning

We use [Semantic Versioning](https://semver.org/) (SemVer):

- **MAJOR** version: Breaking changes
- **MINOR** version: New features (backward compatible)
- **PATCH** version: Bug fixes (backward compatible)

### Release Schedule

- **Regular Releases**: Every 2 weeks from `main` to `production`
- **Hotfixes**: As needed for critical issues
- **Feature Releases**: Based on feature completion

### Release Notes

Each release includes:
- New features and improvements
- Bug fixes
- Breaking changes (if any)
- Migration instructions
- Docker image tags
- Deployment notes

## 🎯 Quality Standards

### Definition of Done

A feature is considered "done" when:

- [ ] Code is written and reviewed
- [ ] Tests are written and passing
- [ ] Documentation is updated
- [ ] CI/CD pipeline passes
- [ ] Security review completed
- [ ] Deployed to staging and tested
- [ ] Ready for production deployment

### Performance Standards

- API response times < 200ms for simple endpoints
- Database queries optimized
- Memory usage within acceptable limits
- Docker images optimized for size
- Kubernetes resource limits configured

Thank you for contributing to our project! 🎉
