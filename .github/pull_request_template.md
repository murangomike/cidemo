# Pull Request

## 📋 Description

Brief description of what this PR accomplishes.

Fixes #(issue number)

## 🔄 Type of Change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Refactoring (no functional changes)
- [ ] Performance improvement
- [ ] Test improvements

## ✅ Testing

- [ ] I have tested this change locally
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] I have tested the Docker build and containers work correctly
- [ ] I have tested the Kubernetes deployment (if applicable)

## 📝 Changes Made

### Backend Changes
- [ ] API endpoints modified/added
- [ ] Database schema changes
- [ ] Environment variables added/modified
- [ ] Dependencies added/updated

### Infrastructure Changes  
- [ ] Dockerfile modified
- [ ] Kubernetes manifests updated
- [ ] CI/CD pipeline changes
- [ ] Docker Compose changes

### Documentation
- [ ] README updated
- [ ] API documentation updated
- [ ] Deployment guides updated
- [ ] Code comments added/updated

## 🔍 Code Review Checklist

### Security
- [ ] No sensitive data (passwords, API keys, etc.) in code
- [ ] Input validation implemented where needed
- [ ] SQL injection prevention considered
- [ ] Authentication/authorization properly handled

### Performance
- [ ] Database queries optimized
- [ ] No obvious performance bottlenecks
- [ ] Memory usage considered
- [ ] Caching implemented where appropriate

### Code Quality
- [ ] Code follows existing patterns and conventions
- [ ] Error handling implemented properly
- [ ] Logging added for important operations
- [ ] Code is readable and well-commented

## 🚀 Deployment Notes

### Database Migrations
- [ ] No database migrations needed
- [ ] Database migrations are backward compatible
- [ ] Migration scripts tested locally

### Environment Variables
- [ ] No new environment variables
- [ ] New environment variables documented
- [ ] Environment variables added to deployment configs

### Breaking Changes
- [ ] No breaking changes
- [ ] Breaking changes documented
- [ ] Migration path provided for breaking changes

## 📸 Screenshots/Videos

If applicable, add screenshots or videos to help explain your changes.

## 🧪 How to Test

1. Step 1...
2. Step 2...
3. Step 3...

## ❓ Questions for Reviewers

- Any specific areas you'd like reviewers to focus on?
- Any architectural decisions you'd like input on?

## 📚 Additional Notes

Any additional information that would be helpful for reviewers or future developers.

---

### For Reviewers

When reviewing this PR, please pay attention to:

1. **Functionality**: Does the code do what it's supposed to do?
2. **Security**: Are there any security vulnerabilities?
3. **Performance**: Will this impact performance?
4. **Maintainability**: Is the code easy to understand and maintain?
5. **Testing**: Are the tests adequate and do they pass?

### Merge Requirements

- [ ] All CI checks pass
- [ ] At least one approval from a code owner
- [ ] All conversations resolved
- [ ] Branch is up to date with main/production
- [ ] Tests pass locally and in CI
