#!/bin/bash

# Kubernetes Scaling Demonstration Script
# This script demonstrates various scaling scenarios and monitoring

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_step() {
    echo -e "${GREEN}➤ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if kubectl is configured
check_kubectl() {
    if ! kubectl cluster-info > /dev/null 2>&1; then
        echo -e "${RED}❌ kubectl is not configured or cluster is not accessible${NC}"
        echo "Please ensure you have a running Kubernetes cluster and kubectl is configured."
        exit 1
    fi
    
    if ! kubectl get namespace crud-app > /dev/null 2>&1; then
        echo -e "${RED}❌ crud-app namespace not found${NC}"
        echo "Please deploy the application first using: ./k8s/deploy.sh start"
        exit 1
    fi
}

# Show current status
show_status() {
    print_header "Current Application Status"
    
    print_step "Deployment status:"
    kubectl get deployment backend -n crud-app -o wide
    
    print_step "Pod status:"
    kubectl get pods -n crud-app -l app=backend -o wide
    
    print_step "HPA status (if enabled):"
    kubectl get hpa backend-hpa -n crud-app 2>/dev/null || echo "HPA not found - run './k8s/deploy.sh hpa' to enable"
    
    print_step "Service status:"
    kubectl get service -n crud-app
}

# Manual scaling demonstration
demo_manual_scaling() {
    print_header "Manual Scaling Demonstration"
    
    print_step "Current replica count:"
    CURRENT_REPLICAS=$(kubectl get deployment backend -n crud-app -o jsonpath='{.spec.replicas}')
    echo "Current replicas: $CURRENT_REPLICAS"
    
    # Scale up to 5 replicas
    print_step "Scaling UP to 5 replicas..."
    kubectl scale deployment backend --replicas=5 -n crud-app
    
    print_info "Waiting for pods to be ready..."
    kubectl wait --for=condition=ready pod -l app=backend -n crud-app --timeout=120s
    
    print_step "New pod status:"
    kubectl get pods -n crud-app -l app=backend
    
    # Monitor for a bit
    print_info "Monitoring resource usage..."
    kubectl top pods -n crud-app -l app=backend || echo "Metrics not available - install metrics-server"
    
    # Scale back down
    echo ""
    read -p "Press Enter to scale back down to $CURRENT_REPLICAS replicas..."
    
    print_step "Scaling DOWN to $CURRENT_REPLICAS replicas..."
    kubectl scale deployment backend --replicas=$CURRENT_REPLICAS -n crud-app
    
    print_info "Waiting for scale down to complete..."
    sleep 10
    
    kubectl get pods -n crud-app -l app=backend
}

# Auto-scaling setup and demonstration
demo_auto_scaling() {
    print_header "Auto-Scaling (HPA) Demonstration"
    
    # Enable HPA if not already enabled
    print_step "Setting up HPA..."
    kubectl apply -f k8s/hpa.yaml -n crud-app
    
    print_info "Waiting for HPA to initialize..."
    sleep 10
    
    print_step "HPA status:"
    kubectl get hpa backend-hpa -n crud-app
    
    print_step "Starting load test to trigger auto-scaling..."
    print_info "This will generate load to increase CPU/Memory usage"
    
    # Get service endpoint
    print_info "Getting service endpoint..."
    
    # Try to get the service URL
    SERVICE_URL=""
    if command -v minikube >/dev/null 2>&1; then
        if minikube status >/dev/null 2>&1; then
            print_info "Using minikube service..."
            SERVICE_URL="http://$(minikube ip):$(kubectl get service backend-loadbalancer -n crud-app -o jsonpath='{.spec.ports[0].nodePort}')"
        fi
    fi
    
    if [ -z "$SERVICE_URL" ]; then
        print_warning "Using port-forward for testing..."
        kubectl port-forward service/backend-service 8080:80 -n crud-app &
        PORT_FORWARD_PID=$!
        sleep 5
        SERVICE_URL="http://localhost:8080"
    fi
    
    echo "Service URL: $SERVICE_URL"
    
    # Test connectivity
    if curl -s "$SERVICE_URL/healthz" > /dev/null; then
        print_step "Service is accessible, starting load test..."
        
        # Run load test in background
        if [ -f "scripts/load-test.js" ]; then
            print_info "Starting load test (30 seconds with 10 concurrent requests)..."
            node scripts/load-test.js "$SERVICE_URL" 10 30 &
            LOAD_TEST_PID=$!
        else
            print_warning "Load test script not found, generating simple load..."
            # Simple load generation with curl
            for i in {1..300}; do
                for j in {1..5}; do
                    curl -s "$SERVICE_URL/users" > /dev/null &
                done
                sleep 0.1
            done &
            LOAD_TEST_PID=$!
        fi
        
        print_step "Monitoring HPA during load test..."
        print_info "Watch for CPU usage to increase and replicas to scale up"
        print_info "Press Ctrl+C to stop monitoring"
        
        # Monitor HPA
        kubectl get hpa backend-hpa -n crud-app -w &
        HPA_MONITOR_PID=$!
        
        # Wait for load test to complete
        wait $LOAD_TEST_PID 2>/dev/null || true
        
        # Stop monitoring
        kill $HPA_MONITOR_PID 2>/dev/null || true
        
        print_step "Final HPA status:"
        kubectl get hpa backend-hpa -n crud-app
        
        print_step "Final pod status:"
        kubectl get pods -n crud-app -l app=backend
        
    else
        print_warning "Service is not accessible, skipping load test"
    fi
    
    # Cleanup port-forward if used
    if [ -n "$PORT_FORWARD_PID" ]; then
        kill $PORT_FORWARD_PID 2>/dev/null || true
    fi
}

# Rolling update demonstration
demo_rolling_update() {
    print_header "Rolling Update Demonstration"
    
    print_step "Current image:"
    kubectl get deployment backend -n crud-app -o jsonpath='{.spec.template.spec.containers[0].image}'
    echo ""
    
    print_step "Simulating rolling update by updating image tag..."
    # We'll just trigger a rollout restart since we don't have multiple image versions
    kubectl rollout restart deployment backend -n crud-app
    
    print_info "Monitoring rolling update..."
    kubectl rollout status deployment backend -n crud-app --timeout=120s
    
    print_step "Rolling update completed!"
    kubectl get pods -n crud-app -l app=backend
    
    print_step "Rollout history:"
    kubectl rollout history deployment backend -n crud-app
    
    print_info "If you need to rollback: kubectl rollout undo deployment backend -n crud-app"
}

# Resource monitoring
demo_monitoring() {
    print_header "Resource Monitoring"
    
    print_step "Pod resource usage:"
    kubectl top pods -n crud-app || print_warning "Metrics server not available"
    
    print_step "Node resource usage:"
    kubectl top nodes || print_warning "Metrics server not available"
    
    print_step "Pod resource limits:"
    kubectl describe deployment backend -n crud-app | grep -A 10 "Limits\|Requests" || true
    
    print_step "Events in the namespace:"
    kubectl get events -n crud-app --sort-by=.metadata.creationTimestamp | tail -10
}

# Performance testing
demo_performance() {
    print_header "Performance Testing"
    
    # Get service endpoint
    SERVICE_URL=""
    if command -v minikube >/dev/null 2>&1; then
        if minikube status >/dev/null 2>&1; then
            SERVICE_URL="http://$(minikube ip):$(kubectl get service backend-loadbalancer -n crud-app -o jsonpath='{.spec.ports[0].nodePort}')"
        fi
    fi
    
    if [ -z "$SERVICE_URL" ]; then
        print_info "Using port-forward for testing..."
        kubectl port-forward service/backend-service 8080:80 -n crud-app &
        PORT_FORWARD_PID=$!
        sleep 5
        SERVICE_URL="http://localhost:8080"
    fi
    
    print_step "Testing API endpoints:"
    
    print_info "Health check:"
    curl -s "$SERVICE_URL/healthz" | jq . || curl -s "$SERVICE_URL/healthz"
    
    print_info "Get users:"
    curl -s "$SERVICE_URL/users" | jq . || curl -s "$SERVICE_URL/users"
    
    print_info "Create user:"
    curl -s -X POST "$SERVICE_URL/users" -H "Content-Type: application/json" -d '{"name":"Demo User"}' | jq . || curl -s -X POST "$SERVICE_URL/users" -H "Content-Type: application/json" -d '{"name":"Demo User"}'
    
    if [ -f "scripts/load-test.js" ]; then
        echo ""
        print_step "Running comprehensive load test (10 seconds)..."
        node scripts/load-test.js "$SERVICE_URL" 5 10
    fi
    
    # Cleanup
    if [ -n "$PORT_FORWARD_PID" ]; then
        kill $PORT_FORWARD_PID 2>/dev/null || true
    fi
}

# Cleanup function
cleanup() {
    print_info "Cleaning up background processes..."
    jobs -p | xargs -r kill 2>/dev/null || true
}

# Trap cleanup on exit
trap cleanup EXIT

# Main menu
show_menu() {
    print_header "Kubernetes Scaling Demonstration"
    echo "Choose a demonstration:"
    echo "1) Show current status"
    echo "2) Manual scaling demo"
    echo "3) Auto-scaling (HPA) demo"
    echo "4) Rolling update demo"
    echo "5) Resource monitoring"
    echo "6) Performance testing"
    echo "7) Run all demonstrations"
    echo "8) Exit"
    echo ""
}

# Main execution
main() {
    check_kubectl
    
    if [ "$#" -eq 1 ]; then
        case "$1" in
            "status"|"1") show_status ;;
            "manual"|"2") demo_manual_scaling ;;
            "auto"|"hpa"|"3") demo_auto_scaling ;;
            "rolling"|"4") demo_rolling_update ;;
            "monitoring"|"5") demo_monitoring ;;
            "performance"|"6") demo_performance ;;
            "all"|"7") 
                show_status
                echo ""
                read -p "Press Enter to continue with manual scaling demo..."
                demo_manual_scaling
                echo ""
                read -p "Press Enter to continue with auto-scaling demo..."
                demo_auto_scaling
                echo ""
                read -p "Press Enter to continue with rolling update demo..."
                demo_rolling_update
                echo ""
                read -p "Press Enter to continue with monitoring demo..."
                demo_monitoring
                echo ""
                read -p "Press Enter to continue with performance testing..."
                demo_performance
                ;;
            *) echo "Unknown option: $1" ;;
        esac
        return
    fi
    
    while true; do
        show_menu
        read -p "Select option (1-8): " choice
        
        case $choice in
            1) show_status ;;
            2) demo_manual_scaling ;;
            3) demo_auto_scaling ;;
            4) demo_rolling_update ;;
            5) demo_monitoring ;;
            6) demo_performance ;;
            7)
                show_status
                echo ""
                read -p "Press Enter to continue with manual scaling demo..."
                demo_manual_scaling
                echo ""
                read -p "Press Enter to continue with auto-scaling demo..."
                demo_auto_scaling
                echo ""
                read -p "Press Enter to continue with rolling update demo..."
                demo_rolling_update
                echo ""
                read -p "Press Enter to continue with monitoring demo..."
                demo_monitoring
                echo ""
                read -p "Press Enter to continue with performance testing..."
                demo_performance
                ;;
            8) 
                print_info "Thanks for using the scaling demonstration!"
                exit 0
                ;;
            *) 
                print_warning "Invalid option. Please select 1-8."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to return to menu..."
    done
}

main "$@"
