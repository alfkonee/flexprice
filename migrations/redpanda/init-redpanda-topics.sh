#!/bin/bash

# Create topics directly using rpk (which will use local socket communication)
echo "Creating Redpanda topics..."

rpk topic create events --if-not-exists
rpk topic create events_lazy --if-not-exists
rpk topic create events_post_processing --if-not-exists
rpk topic create system_events --if-not-exists
rpk topic create wallet_alert --if-not-exists
rpk topic create event_processing_backfill --if-not-exists
rpk topic create event_processing_lazy_backfill --if-not-exists
rpk topic create events_post_processing_backfill --if-not-exists
rpk topic create v1_feature_tracking_service_backfill --if-not-exists
rpk topic create v1_feature_tracking_service_lazy_backfill --if-not-exists

echo "All topics created successfully!"
rpk topic list
