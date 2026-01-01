#!/bin/bash

# This script creates all the required Kafka topics
# It's designed to run after Kafka is fully started

KAFKA_BROKER="kafka:9092"

# Function to create a topic
create_topic() {
    local topic=$1
    echo "Creating topic: $topic"
    kafka-topics --bootstrap-server $KAFKA_BROKER --create --topic "$topic" --partitions 1 --replication-factor 1 --if-not-exists
}

# Wait for Kafka to be ready
echo "Waiting for Kafka to be ready..."
kafka-broker-api-versions --bootstrap-server $KAFKA_BROKER > /dev/null 2>&1
while [ $? -ne 0 ]; do
    echo "Kafka not ready yet, waiting..."
    sleep 2
    kafka-broker-api-versions --bootstrap-server $KAFKA_BROKER > /dev/null 2>&1
done

echo "Kafka is ready, creating topics..."

# Create all required topics
create_topic "events"
create_topic "events_lazy"
create_topic "events_post_processing"
create_topic "system_events"
create_topic "wallet_alert"

# Additional backfill/deadletter topics that might be needed
create_topic "event_processing_backfill"
create_topic "event_processing_lazy_backfill"
create_topic "events_post_processing_backfill"
create_topic "v1_feature_tracking_service_backfill"
create_topic "v1_feature_tracking_service_lazy_backfill"

echo "All topics created successfully!"
