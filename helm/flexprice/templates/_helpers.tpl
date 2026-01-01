{{/*
Expand the name of the chart.
*/}}
{{- define "flexprice.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "flexprice.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "flexprice.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "flexprice.labels" -}}
helm.sh/chart: {{ include "flexprice.chart" . }}
{{ include "flexprice.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "flexprice.selectorLabels" -}}
app.kubernetes.io/name: {{ include "flexprice.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
API selector labels
*/}}
{{- define "flexprice.api.selectorLabels" -}}
{{ include "flexprice.selectorLabels" . }}
app.kubernetes.io/component: api
{{- end }}

{{/*
Consumer selector labels
*/}}
{{- define "flexprice.consumer.selectorLabels" -}}
{{ include "flexprice.selectorLabels" . }}
app.kubernetes.io/component: consumer
{{- end }}

{{/*
Worker selector labels
*/}}
{{- define "flexprice.worker.selectorLabels" -}}
{{ include "flexprice.selectorLabels" . }}
app.kubernetes.io/component: worker
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "flexprice.serviceAccountName" -}}
{{- if .Values.flexprice.serviceAccount.create }}
{{- default (include "flexprice.fullname" .) .Values.flexprice.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.flexprice.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get PostgreSQL host
*/}}
{{- define "flexprice.postgres.host" -}}
{{- if .Values.postgres.external.enabled }}
{{- .Values.postgres.external.host }}
{{- else }}
{{- printf "%s-postgres" (include "flexprice.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Get PostgreSQL reader host
*/}}
{{- define "flexprice.postgres.readerHost" -}}
{{- if .Values.postgres.external.enabled }}
{{- default (include "flexprice.postgres.host" .) .Values.postgres.external.readerHost }}
{{- else }}
{{- printf "%s-postgres-replica" (include "flexprice.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Get PostgreSQL port
*/}}
{{- define "flexprice.postgres.port" -}}
{{- if .Values.postgres.external.enabled }}
{{- .Values.postgres.external.port }}
{{- else }}
{{- 5432 }}
{{- end }}
{{- end }}

{{/*
Get PostgreSQL user
*/}}
{{- define "flexprice.postgres.user" -}}
{{- if .Values.postgres.external.enabled }}
{{- .Values.postgres.external.user }}
{{- else }}
{{- .Values.postgres.user }}
{{- end }}
{{- end }}

{{/*
Get PostgreSQL database
*/}}
{{- define "flexprice.postgres.database" -}}
{{- if .Values.postgres.external.enabled }}
{{- .Values.postgres.external.database }}
{{- else }}
{{- .Values.postgres.database }}
{{- end }}
{{- end }}

{{/*
Get PostgreSQL SSL mode
*/}}
{{- define "flexprice.postgres.sslMode" -}}
{{- if .Values.postgres.external.enabled }}
{{- .Values.postgres.external.sslMode }}
{{- else }}
{{- "disable" }}
{{- end }}
{{- end }}

{{/*
Get ClickHouse address
*/}}
{{- define "flexprice.clickhouse.address" -}}
{{- if .Values.clickhouse.external.enabled }}
{{- .Values.clickhouse.external.address }}
{{- else }}
{{- printf "%s-clickhouse:9000" (include "flexprice.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Get ClickHouse TLS setting
*/}}
{{- define "flexprice.clickhouse.tls" -}}
{{- if .Values.clickhouse.external.enabled }}
{{- .Values.clickhouse.external.tls }}
{{- else }}
{{- false }}
{{- end }}
{{- end }}

{{/*
Get ClickHouse user
*/}}
{{- define "flexprice.clickhouse.user" -}}
{{- if .Values.clickhouse.external.enabled }}
{{- .Values.clickhouse.external.user }}
{{- else }}
{{- .Values.clickhouse.user }}
{{- end }}
{{- end }}

{{/*
Get ClickHouse database
*/}}
{{- define "flexprice.clickhouse.database" -}}
{{- if .Values.clickhouse.external.enabled }}
{{- .Values.clickhouse.external.database }}
{{- else }}
{{- .Values.clickhouse.database }}
{{- end }}
{{- end }}

{{/*
Get Kafka brokers
*/}}
{{- define "flexprice.kafka.brokers" -}}
{{- if .Values.kafka.external.enabled }}
{{- .Values.kafka.external.brokers | join "," }}
{{- else }}
{{- printf "%s-redpanda:9092" (include "flexprice.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Get Kafka TLS setting
*/}}
{{- define "flexprice.kafka.tls" -}}
{{- if .Values.kafka.external.enabled }}
{{- .Values.kafka.external.tls }}
{{- else }}
{{- false }}
{{- end }}
{{- end }}

{{/*
Get Kafka SASL enabled
*/}}
{{- define "flexprice.kafka.saslEnabled" -}}
{{- if .Values.kafka.external.enabled }}
{{- .Values.kafka.external.sasl.enabled }}
{{- else }}
{{- false }}
{{- end }}
{{- end }}

{{/*
Get Temporal address
*/}}
{{- define "flexprice.temporal.address" -}}
{{- if .Values.temporal.external.enabled }}
{{- .Values.temporal.external.address }}
{{- else }}
{{- printf "%s-temporal-frontend:7233" (include "flexprice.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Get Temporal namespace
*/}}
{{- define "flexprice.temporal.namespace" -}}
{{- if .Values.temporal.external.enabled }}
{{- .Values.temporal.external.namespace }}
{{- else }}
{{- .Values.temporal.namespace }}
{{- end }}
{{- end }}

{{/*
Get Temporal TLS setting
*/}}
{{- define "flexprice.temporal.tls" -}}
{{- if .Values.temporal.external.enabled }}
{{- .Values.temporal.external.tls }}
{{- else }}
{{- false }}
{{- end }}
{{- end }}

{{/*
Secret name for database credentials
*/}}
{{- define "flexprice.secretName" -}}
{{- if .Values.secrets.existingSecret }}
{{- .Values.secrets.existingSecret }}
{{- else }}
{{- printf "%s-secrets" (include "flexprice.fullname" .) }}
{{- end }}
{{- end }}

{{/*
PostgreSQL secret name
*/}}
{{- define "flexprice.postgres.secretName" -}}
{{- if .Values.postgres.external.existingSecret }}
{{- .Values.postgres.external.existingSecret }}
{{- else }}
{{- printf "%s-postgres-credentials" (include "flexprice.fullname" .) }}
{{- end }}
{{- end }}

{{/*
ClickHouse secret name
*/}}
{{- define "flexprice.clickhouse.secretName" -}}
{{- if .Values.clickhouse.external.existingSecret }}
{{- .Values.clickhouse.external.existingSecret }}
{{- else }}
{{- printf "%s-clickhouse-credentials" (include "flexprice.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Kafka secret name
*/}}
{{- define "flexprice.kafka.secretName" -}}
{{- if and .Values.kafka.external.enabled .Values.kafka.external.sasl.existingSecret }}
{{- .Values.kafka.external.sasl.existingSecret }}
{{- else }}
{{- printf "%s-kafka-credentials" (include "flexprice.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Temporal secret name
*/}}
{{- define "flexprice.temporal.secretName" -}}
{{- if and .Values.temporal.external.enabled .Values.temporal.external.existingSecret }}
{{- .Values.temporal.external.existingSecret }}
{{- else }}
{{- printf "%s-temporal-credentials" (include "flexprice.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Generate random password
*/}}
{{- define "flexprice.randomPassword" -}}
{{- randAlphaNum 32 }}
{{- end }}

{{/*
Generate random secret
*/}}
{{- define "flexprice.randomSecret" -}}
{{- randAlphaNum 64 | sha256sum }}
{{- end }}
