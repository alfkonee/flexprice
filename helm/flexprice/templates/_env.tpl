{{/*
Environment variables for FlexPrice containers
*/}}
{{- define "flexprice.envVars" -}}
# PostgreSQL configuration
- name: FLEXPRICE_POSTGRES_HOST
  value: {{ include "flexprice.postgres.host" . | quote }}
- name: FLEXPRICE_POSTGRES_PORT
  value: {{ include "flexprice.postgres.port" . | quote }}
- name: FLEXPRICE_POSTGRES_READER_HOST
  value: {{ include "flexprice.postgres.readerHost" . | quote }}
- name: FLEXPRICE_POSTGRES_USER
  value: {{ include "flexprice.postgres.user" . | quote }}
- name: FLEXPRICE_POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "flexprice.postgres.secretName" . }}
      key: {{ if .Values.postgres.external.existingSecret }}{{ .Values.postgres.external.passwordKey }}{{ else }}password{{ end }}
- name: FLEXPRICE_POSTGRES_DBNAME
  value: {{ include "flexprice.postgres.database" . | quote }}
- name: FLEXPRICE_POSTGRES_SSLMODE
  value: {{ include "flexprice.postgres.sslMode" . | quote }}
- name: FLEXPRICE_POSTGRES_MAX_OPEN_CONNS
  value: {{ .Values.postgres.maxOpenConns | quote }}
- name: FLEXPRICE_POSTGRES_MAX_IDLE_CONNS
  value: {{ .Values.postgres.maxIdleConns | quote }}
- name: FLEXPRICE_POSTGRES_CONN_MAX_LIFETIME_MINUTES
  value: {{ .Values.postgres.connMaxLifetimeMinutes | quote }}

# ClickHouse configuration
- name: FLEXPRICE_CLICKHOUSE_ADDRESS
  value: {{ include "flexprice.clickhouse.address" . | quote }}
- name: FLEXPRICE_CLICKHOUSE_TLS
  value: {{ include "flexprice.clickhouse.tls" . | quote }}
- name: FLEXPRICE_CLICKHOUSE_USERNAME
  value: {{ include "flexprice.clickhouse.user" . | quote }}
- name: FLEXPRICE_CLICKHOUSE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "flexprice.clickhouse.secretName" . }}
      key: {{ if .Values.clickhouse.external.existingSecret }}{{ .Values.clickhouse.external.passwordKey }}{{ else }}password{{ end }}
- name: FLEXPRICE_CLICKHOUSE_DATABASE
  value: {{ include "flexprice.clickhouse.database" . | quote }}

# Kafka configuration
- name: FLEXPRICE_KAFKA_BROKERS
  value: {{ include "flexprice.kafka.brokers" . | quote }}
- name: FLEXPRICE_KAFKA_TLS
  value: {{ include "flexprice.kafka.tls" . | quote }}
- name: FLEXPRICE_KAFKA_USE_SASL
  value: {{ include "flexprice.kafka.saslEnabled" . | quote }}
{{- if and .Values.kafka.external.enabled .Values.kafka.external.sasl.enabled }}
- name: FLEXPRICE_KAFKA_SASL_MECHANISM
  value: {{ .Values.kafka.external.sasl.mechanism | quote }}
- name: FLEXPRICE_KAFKA_SASL_USER
  valueFrom:
    secretKeyRef:
      name: {{ include "flexprice.kafka.secretName" . }}
      key: {{ if .Values.kafka.external.sasl.existingSecret }}{{ .Values.kafka.external.sasl.userKey }}{{ else }}username{{ end }}
- name: FLEXPRICE_KAFKA_SASL_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "flexprice.kafka.secretName" . }}
      key: {{ if .Values.kafka.external.sasl.existingSecret }}{{ .Values.kafka.external.sasl.passwordKey }}{{ else }}password{{ end }}
{{- end }}
- name: FLEXPRICE_KAFKA_CONSUMER_GROUP
  value: {{ .Values.kafka.consumerGroup | quote }}
- name: FLEXPRICE_KAFKA_CLIENT_ID
  value: {{ .Values.kafka.clientId | quote }}

# Temporal configuration
- name: FLEXPRICE_TEMPORAL_ADDRESS
  value: {{ include "flexprice.temporal.address" . | quote }}
- name: FLEXPRICE_TEMPORAL_NAMESPACE
  value: {{ include "flexprice.temporal.namespace" . | quote }}
- name: FLEXPRICE_TEMPORAL_TLS
  value: {{ include "flexprice.temporal.tls" . | quote }}
- name: FLEXPRICE_TEMPORAL_TASK_QUEUE
  value: {{ .Values.temporal.taskQueue | quote }}
- name: FLEXPRICE_TEMPORAL_CLIENT_NAME
  value: {{ .Values.temporal.clientName | quote }}
{{- if or .Values.temporal.external.apiKey (and .Values.temporal.external.existingSecret .Values.temporal.external.apiKeySecretKey) }}
- name: FLEXPRICE_TEMPORAL_API_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "flexprice.temporal.secretName" . }}
      key: {{ if .Values.temporal.external.existingSecret }}{{ .Values.temporal.external.apiKeySecretKey }}{{ else }}api-key{{ end }}
{{- end }}

# Auth configuration
- name: FLEXPRICE_AUTH_PROVIDER
  value: {{ .Values.auth.provider | quote }}
- name: FLEXPRICE_AUTH_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "flexprice.secretName" . }}
      key: {{ if .Values.secrets.existingSecret }}{{ .Values.secrets.authSecretKey }}{{ else }}auth-secret{{ end }}
{{- if eq .Values.auth.provider "supabase" }}
- name: FLEXPRICE_AUTH_SUPABASE_BASE_URL
  value: {{ .Values.auth.supabase.baseUrl | quote }}
- name: FLEXPRICE_AUTH_SUPABASE_SERVICE_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "flexprice.secretName" . }}
      key: supabase-service-key
{{- end }}

# Secrets configuration
- name: FLEXPRICE_SECRETS_ENCRYPTION_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "flexprice.secretName" . }}
      key: {{ if .Values.secrets.existingSecret }}{{ .Values.secrets.encryptionKeySecretKey }}{{ else }}encryption-key{{ end }}

# Observability configuration
- name: FLEXPRICE_SENTRY_ENABLED
  value: {{ .Values.observability.sentry.enabled | quote }}
{{- if .Values.observability.sentry.enabled }}
- name: FLEXPRICE_SENTRY_DSN
  value: {{ .Values.observability.sentry.dsn | quote }}
- name: FLEXPRICE_SENTRY_ENVIRONMENT
  value: {{ .Values.observability.sentry.environment | quote }}
- name: FLEXPRICE_SENTRY_SAMPLE_RATE
  value: {{ .Values.observability.sentry.sampleRate | quote }}
{{- end }}
- name: FLEXPRICE_PYROSCOPE_ENABLED
  value: {{ .Values.observability.pyroscope.enabled | quote }}
{{- if .Values.observability.pyroscope.enabled }}
- name: FLEXPRICE_PYROSCOPE_SERVER_ADDRESS
  value: {{ .Values.observability.pyroscope.serverAddress | quote }}
- name: FLEXPRICE_PYROSCOPE_APPLICATION_NAME
  value: {{ .Values.observability.pyroscope.applicationName | quote }}
{{- end }}
- name: FLEXPRICE_LOGGING_LEVEL
  value: {{ .Values.observability.logging.level | quote }}

# Email configuration
- name: FLEXPRICE_EMAIL_ENABLED
  value: {{ .Values.email.enabled | quote }}
{{- if .Values.email.enabled }}
- name: FLEXPRICE_EMAIL_FROM_ADDRESS
  value: {{ .Values.email.fromAddress | quote }}
- name: FLEXPRICE_EMAIL_REPLY_TO
  value: {{ .Values.email.replyTo | quote }}
- name: FLEXPRICE_EMAIL_RESEND_API_KEY
  valueFrom:
    secretKeyRef:
      name: {{ if .Values.email.existingSecret }}{{ .Values.email.existingSecret }}{{ else }}{{ include "flexprice.fullname" . }}-email{{ end }}
      key: {{ if .Values.email.existingSecret }}{{ .Values.email.apiKeySecretKey }}{{ else }}resend-api-key{{ end }}
{{- end }}

# S3 configuration
- name: FLEXPRICE_S3_ENABLED
  value: {{ .Values.s3.enabled | quote }}
{{- if .Values.s3.enabled }}
- name: FLEXPRICE_S3_REGION
  value: {{ .Values.s3.region | quote }}
- name: FLEXPRICE_S3_INVOICE_BUCKET
  value: {{ .Values.s3.invoice.bucket | quote }}
{{- if .Values.s3.credentials.existingSecret }}
- name: AWS_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: {{ .Values.s3.credentials.existingSecret }}
      key: {{ .Values.s3.credentials.accessKeyIdKey }}
- name: AWS_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.s3.credentials.existingSecret }}
      key: {{ .Values.s3.credentials.secretAccessKeyKey }}
{{- else if and .Values.s3.credentials.accessKeyId .Values.s3.credentials.secretAccessKey }}
- name: AWS_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: {{ include "flexprice.fullname" . }}-s3
      key: access-key-id
- name: AWS_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "flexprice.fullname" . }}-s3
      key: secret-access-key
{{- end }}
{{- end }}

# Cache configuration
- name: FLEXPRICE_CACHE_ENABLED
  value: {{ .Values.cache.enabled | quote }}

# Webhook configuration
- name: FLEXPRICE_WEBHOOK_ENABLED
  value: {{ .Values.webhook.enabled | quote }}
- name: FLEXPRICE_WEBHOOK_TOPIC
  value: {{ .Values.webhook.topic | quote }}
- name: FLEXPRICE_WEBHOOK_PUBSUB
  value: {{ .Values.webhook.pubsub | quote }}
{{- if .Values.webhook.svix.enabled }}
- name: FLEXPRICE_WEBHOOK_SVIX_ENABLED
  value: "true"
- name: FLEXPRICE_WEBHOOK_SVIX_BASE_URL
  value: {{ .Values.webhook.svix.baseUrl | quote }}
- name: FLEXPRICE_WEBHOOK_SVIX_AUTH_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ if .Values.webhook.svix.existingSecret }}{{ .Values.webhook.svix.existingSecret }}{{ else }}{{ include "flexprice.fullname" . }}-svix{{ end }}
      key: {{ if .Values.webhook.svix.existingSecret }}{{ .Values.webhook.svix.authTokenKey }}{{ else }}auth-token{{ end }}
{{- end }}

# Feature flags
- name: FLEXPRICE_FEATURE_FLAG_ENABLE_FEATURE_USAGE_FOR_ANALYTICS
  value: {{ .Values.featureFlags.enableFeatureUsageForAnalytics | quote }}
{{- if .Values.featureFlags.forceV1ForTenant }}
- name: FLEXPRICE_FEATURE_FLAG_FORCE_V1_FOR_TENANT
  value: {{ .Values.featureFlags.forceV1ForTenant | quote }}
{{- end }}

# RBAC configuration
- name: FLEXPRICE_RBAC_ROLES_CONFIG_PATH
  value: {{ .Values.rbac.rolesConfigPath | quote }}

# OAuth configuration
{{- if .Values.oauth.redirectUri }}
- name: FLEXPRICE_OAUTH_REDIRECT_URI
  value: {{ .Values.oauth.redirectUri | quote }}
{{- end }}
{{- end }}
