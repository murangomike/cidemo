#!/bin/bash

# Kubernetes Deployment Script for CRUD Backend Application
# This script helps with deploying, scaling, and managing the application in Kubernetes

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if minikube is running
check_minikube() {
    if ! minikube status > /dev/null 2>&1; then
        print_warning "Minikube is not running. Starting minikube..."
        minikube start --driver=docker --memory=4g --cpus=2
        minikube addons enable metrics-server
        print_success "Minikube started successfully"
    else
        print_success "Minikube is already running"
    fi
}

# Function to load Docker image into minikube
load_image() {
    print_status "Loading Docker image into minikube..."
    minikube image load backend-backend:latest
    print_success "Docker image loaded into minikube"
}

# Function to deploy the application
deploy() {
    print_status "Deploying CRUD Backend Application to Kubernetes..."
    
    # Apply namespace first
    kubectl apply -f k8s/namespace.yaml
    
    # Apply PostgreSQL components
    kubectl apply -f k8s/postgres.yaml -n crud-app
    
    # Wait for PostgreSQL to be ready
    print_status "Waiting for PostgreSQL to be ready..."
    kubectl wait --for=condition=ready pod -l app=postgres -n crud-app --timeout=300s
    
    # Apply backend components
    kubectl apply -f k8s/backend.yaml -n crud-app
    
    # Wait for backend to be ready
    print_status "Waiting for backend to be ready..."
    kubectl wait --for=condition=ready pod -l app=backend -n crud-app --timeout=300s
    
    print_success "Application deployed successfully!"
}

# Function to show application status
status() {
    print_status "Application Status:"
    echo
    kubectl get all -n crud-app
    echo
    kubectl get pv,pvc -n crud-app
    echo
    print_status "Pod details:"
    kubectl get pods -n crud-app -o wide
}

# Function to scale the application
scale() {
    local replicas=$1
    if [[ -z "$replicas" ]]; then
        print_error "Please specify number of replicas: ./deploy.sh scale <number>"
        exit 1
    fi
    
    print_status "Scaling backend to $replicas replicas..."
    kubectl scale deployment backend --replicas=$replicas -n crud-app
    kubectl wait --for=condition=ready pod -l app=backend -n crud-app --timeout=300s
    print_success "Backend scaled to $replicas replicas"
}

# Function to enable HPA (Horizontal Pod Autoscaler)
enable_hpa() {
    print_status "Enabling Horizontal Pod Autoscaler..."
    kubectl apply -f k8s/hpa.yaml -n crud-app
    print_success "HPA enabled. Use 'kubectl get hpa -n crud-app' to monitor"
}

# Function to test the application
test() {
    print_status "Testing the application..."
    
    # Get the service URL
    local service_url=$(minikube service backend-loadbalancer -n crud-app --url)
    
    print_status "Service URL: $service_url"
    
    # Test health endpoint
    print_status "Testing health endpoint..."
    curl -s "$service_url/healthz" | jq .
    
    print_status "Testing users endpoint..."
    curl -s "$service_url/users" | jq .
    
    print_status "Creating a test user..."
    curl -s -X POST "$service_url/users" \
         -H "Content-Type: application/json" \
         -d '{"name":"K8s Test User"}' | jq .
    
    print_success "Application tests completed!"
}

# Function to generate load for testing autoscaling
load_test() {
    print_status "Starting load test to trigger autoscaling..."
    local service_url=$(minikube service backend-loadbalancer -n crud-app --url)
    
    print_status "Running load test on $service_url"
    print_warning "This will run for 5 minutes. Monitor with: kubectl get hpa -n crud-app -w"
    
    # Run load test using Apache Bench or curl in a loop
    for i in {1..300}; do
        for j in {1..10}; do
            curl -s "$service_url/users" > /dev/null &
        done
        sleep 1
    done
    
    print_success "Load test completed"
}

# Function to clean up
cleanup() {
    print_status "Cleaning up resources..."
    kubectl delete namespace crud-app --ignore-not-found=true
    kubectl delete pv postgres-pv --ignore-not-found=true
    print_success "Resources cleaned up"
}

# Function to show logs
logs() {
    local component=$1
    if [[ -z "$component" ]]; then
        print_error "Please specify component: ./deploy.sh logs <backend|postgres>"
        exit 1
    fi
    
    kubectl logs -f deployment/$component -n crud-app
}

# Function to port-forward for local access
port_forward() {
    print_status "Setting up port forwarding..."
    print_status "Backend will be available at http://localhost:3000"
    kubectl port-forward service/backend-service 3000:80 -n crud-app
}

# Main script logic
case "$1" in
    "start")
        check_minikube
        load_image
        deploy
        status
        ;;
    "deploy")
        deploy
        ;;
    "status")
        status
        ;;
    "scale")
        scale $2
        ;;
    "hpa")
        enable_hpa
        ;;
    "test")
        test
        ;;
    "load-test")
        load_test
        ;;
    "logs")
        logs $2
        ;;
    "port-forward")
        port_forward
        ;;
    "cleanup")
        cleanup
        ;;
    "minikube")
        check_minikube
        ;;
    *)
        echo "Usage: $0 {start|deploy|status|scale|hpa|test|load-test|logs|port-forward|cleanup|minikube}"
        echo
        echo "Commands:"
        echo "  start       - Start minikube, load image, and deploy application"
        echo "  deploy      - Deploy the application to Kubernetes"
        echo "  status      - Show application status"
        echo "  scale <n>   - Scale backend to n replicas"
        echo "  hpa         - Enable Horizontal Pod Autoscaler"
        echo "  test        - Test the deployed application"
        echo "  load-test   - Generate load to test autoscaling"
        echo "  logs <comp> - Show logs for component (backend|postgres)"
        echo "  port-forward- Set up port forwarding for local access"
        echo "  cleanup     - Remove all resources"
        echo "  minikube    - Start minikube if not running"
        exit 1
        ;;
esac
