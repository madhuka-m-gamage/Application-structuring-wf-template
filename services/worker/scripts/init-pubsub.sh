#!/bin/sh
# ==============================================================================
# Cloud Pub/Sub Emulator Topic & Subscription Initialization Script
# Conforms to contracts/events/ standards (DLQ, Push Subscription)
# ==============================================================================
set -e

HOST="${PUBSUB_EMULATOR_HOST:-pubsub-emulator:8085}"
PROJECT="${PUBSUB_PROJECT_ID:-local-project}"
WORKER_ENDPOINT="${WORKER_PUSH_ENDPOINT:-http://worker:8080/events/push}"

echo "============================================================"
echo "Initializing Cloud Pub/Sub Emulator at ${HOST}"
echo "Project ID: ${PROJECT}"
echo "============================================================"

# Wait for emulator to become responsive
echo "Waiting for Pub/Sub emulator to be reachable at ${HOST}..."
MAX_ATTEMPTS=30
ATTEMPT=1
until wget -qO- "http://${HOST}/v1/projects/${PROJECT}/topics" > /dev/null 2>&1 || curl -sf "http://${HOST}/v1/projects/${PROJECT}/topics" > /dev/null 2>&1; do
  if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
    echo "ERROR: Pub/Sub emulator failed to start within $((MAX_ATTEMPTS * 2)) seconds."
    exit 1
  fi
  echo "Attempt $ATTEMPT/$MAX_ATTEMPTS: Emulator not ready yet, sleeping 2s..."
  sleep 2
  ATTEMPT=$((ATTEMPT + 1))
done
echo "Pub/Sub emulator is online!"

# Function to create topic
create_topic() {
  TOPIC_NAME="$1"
  echo "Creating topic: ${TOPIC_NAME}..."
  if command -v curl > /dev/null 2>&1; then
    curl -s -X PUT "http://${HOST}/v1/projects/${PROJECT}/topics/${TOPIC_NAME}" \
      -H "Content-Type: application/json" > /dev/null
  else
    wget -qO- --post-data="" --header="Content-Type: application/json" \
      "http://${HOST}/v1/projects/${PROJECT}/topics/${TOPIC_NAME}" > /dev/null 2>&1 || true
  fi
  echo "Topic ${TOPIC_NAME} confirmed."
}

# Function to create push subscription
create_push_subscription() {
  SUB_NAME="$1"
  TOPIC_NAME="$2"
  PUSH_URL="$3"
  echo "Creating push subscription: ${SUB_NAME} -> ${PUSH_URL}..."
  
  PAYLOAD="{\"topic\": \"projects/${PROJECT}/topics/${TOPIC_NAME}\", \"pushConfig\": {\"pushEndpoint\": \"${PUSH_URL}\"}, \"ackDeadlineSeconds\": 60, \"deadLetterPolicy\": {\"deadLetterTopic\": \"projects/${PROJECT}/topics/tasks-dlq\", \"maxDeliveryAttempts\": 5}}"

  if command -v curl > /dev/null 2>&1; then
    curl -s -X PUT "http://${HOST}/v1/projects/${PROJECT}/subscriptions/${SUB_NAME}" \
      -H "Content-Type: application/json" \
      -d "${PAYLOAD}" > /dev/null
  else
    wget -qO- --post-data="${PAYLOAD}" --header="Content-Type: application/json" \
      "http://${HOST}/v1/projects/${PROJECT}/subscriptions/${SUB_NAME}" > /dev/null 2>&1 || true
  fi
  echo "Push subscription ${SUB_NAME} configured."
}

# Function to create pull subscription
create_pull_subscription() {
  SUB_NAME="$1"
  TOPIC_NAME="$2"
  echo "Creating pull subscription: ${SUB_NAME}..."
  
  PAYLOAD="{\"topic\": \"projects/${PROJECT}/topics/${TOPIC_NAME}\", \"ackDeadlineSeconds\": 60}"

  if command -v curl > /dev/null 2>&1; then
    curl -s -X PUT "http://${HOST}/v1/projects/${PROJECT}/subscriptions/${SUB_NAME}" \
      -H "Content-Type: application/json" \
      -d "${PAYLOAD}" > /dev/null
  else
    wget -qO- --post-data="${PAYLOAD}" --header="Content-Type: application/json" \
      "http://${HOST}/v1/projects/${PROJECT}/subscriptions/${SUB_NAME}" > /dev/null 2>&1 || true
  fi
  echo "Pull subscription ${SUB_NAME} configured."
}

# 1. Create Topics
create_topic "tasks"
create_topic "tasks-dlq"
create_topic "task-events"

# 2. Create Subscriptions
create_push_subscription "worker-task-created-sub" "tasks" "${WORKER_ENDPOINT}"
create_pull_subscription "task-events-sub" "task-events"
create_pull_subscription "tasks-dlq-sub" "tasks-dlq"

echo "============================================================"
echo "Pub/Sub topics and subscriptions successfully initialized!"
echo "============================================================"
