#!/bin/bash

# Fix Docker API version mismatch
export DOCKER_API_VERSION=1.43

##########################
# Check if cluster is ready before running tests
echo "[post-start] Checking if cluster is ready..."

# Wait for kubectl to be accessible (max 60 seconds)
TIMEOUT=60
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    if kubectl cluster-info &> /dev/null; then
        echo "[post-start] Cluster is accessible"
        break
    fi
    echo "[post-start] Waiting for cluster... (${ELAPSED}s)"
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

# Verify cluster is actually accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "[post-start] ERROR: Kubernetes cluster is not accessible after ${TIMEOUT}s"
    echo "[post-start] Skipping pytest tests. Please check cluster status with: docker ps -a | grep kind"
    exit 0  # Exit 0 to not fail the postStart command
fi

##########################
# 2. Run test harness
echo "[post-start] Running pytest test harness..."
export OTEL_SERVICE_NAME=codespace-platform
export PYTEST_RUN_NAME=startup-automated-test
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
pytest --export-traces codespaces_test.py || {
    echo "[post-start] Pytest tests failed. Check logs above for details."
    exit 0  # Exit 0 to not fail the postStart command completely
}