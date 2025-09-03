{{/*
Expand the name of the chart.
*/}}
{{- define "torchserve.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "torchserve.fullname" -}}
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
{{- define "torchserve.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "torchserve.labels" -}}
helm.sh/chart: {{ include "torchserve.chart" . }}
{{ include "torchserve.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "torchserve.selectorLabels" -}}
app.kubernetes.io/name: {{ include "torchserve.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "torchserve.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "torchserve.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the configmap to use
*/}}
{{- define "torchserve.configMapName" -}}
{{- if .Values.configMap.create }}
{{- printf "%s-config" (include "torchserve.fullname" .) }}
{{- else }}
{{- printf "%s-config" (include "torchserve.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Create the name of the secret to use
*/}}
{{- define "torchserve.secretName" -}}
{{- if .Values.secret.create }}
{{- printf "%s-secret" (include "torchserve.fullname" .) }}
{{- else }}
{{- printf "%s-secret" (include "torchserve.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Return the proper TorchServe image name
*/}}
{{- define "torchserve.image" -}}
{{- printf "%s:%s" .Values.image.repository (default .Chart.AppVersion .Values.image.tag) }}
{{- end }}

{{/*
Return TorchServe config.properties content
*/}}
{{- define "torchserve.config" -}}
inference_address=http://0.0.0.0:{{ .Values.torchserve.config.inferencePort }}
management_address=http://0.0.0.0:{{ .Values.torchserve.config.managementPort }}
metrics_address=http://0.0.0.0:{{ .Values.torchserve.config.metricsPort }}
grpc_inference_port={{ .Values.torchserve.config.grpcInferencePort }}
grpc_management_port={{ .Values.torchserve.config.grpcManagementPort }}
model_store={{ .Values.torchserve.config.modelStore }}
{{- if .Values.torchserve.config.workflowStore }}
workflow_store={{ .Values.torchserve.config.workflowStore }}
{{- end }}
default_workers_per_model={{ .Values.torchserve.config.defaultWorkersPerModel }}
max_workers={{ .Values.torchserve.config.maxWorkers }}
batch_size={{ .Values.torchserve.config.batchSize }}
max_batch_delay={{ .Values.torchserve.config.maxBatchDelay }}
number_of_netty_threads={{ .Values.torchserve.config.numberOfNettyThreads }}
job_queue_size={{ .Values.torchserve.config.jobQueueSize }}
{{- if .Values.torchserve.config.asyncLogging }}
async_logging=true
{{- end }}
{{- if .Values.torchserve.config.enableModelVersioning }}
model_versioning=true
{{- end }}
install_py_dep_per_model={{ .Values.torchserve.config.installPyDepPerModel }}
{{- if .Values.torchserve.config.enableEnvvarsConfig }}
enable_envvars_config=true
{{- end }}
{{- if .Values.torchserve.config.disableTokenAuthorization }}
disable_token_authorization=true
{{- end }}
# Kubernetes-friendly logging to stdout
enable_logging=true
log_location=
metrics_location=
{{- if .Values.torchserve.config.additionalConfig }}
{{ .Values.torchserve.config.additionalConfig }}
{{- end }}
{{- end }}

{{/*
Return TorchServe model config content
*/}}
{{- define "torchserve.modelConfig" -}}
{{- range $name, $config := .Values.torchserve.models }}
[{{ $name }}]
{{- if $config.url }}
url={{ $config.url }}
{{- end }}
{{- if $config.initialWorkers }}
initial_workers={{ $config.initialWorkers }}
{{- end }}
{{- if $config.batchSize }}
batch_size={{ $config.batchSize }}
{{- end }}
{{- if $config.maxBatchDelay }}
max_batch_delay={{ $config.maxBatchDelay }}
{{- end }}
{{- if $config.responseTimeout }}
response_timeout={{ $config.responseTimeout }}
{{- end }}

{{- end }}
{{- end }}

{{/*
Return the PVC name for model store
*/}}
{{- define "torchserve.modelStorePvcName" -}}
{{- printf "%s-model-store" (include "torchserve.fullname" .) }}
{{- end }}

{{/*
Return the PVC name for workflow store
*/}}
{{- define "torchserve.workflowStorePvcName" -}}
{{- printf "%s-workflow-store" (include "torchserve.fullname" .) }}
{{- end }}

{{/*
Return true if a model store PVC should be created
*/}}
{{- define "torchserve.createModelStorePvc" -}}
{{- if and .Values.persistence.enabled (not .Values.persistence.existingClaim) }}
{{- true }}
{{- end }}
{{- end }}

{{/*
Return true if a workflow store PVC should be created
*/}}
{{- define "torchserve.createWorkflowStorePvc" -}}
{{- if and .Values.workflowPersistence.enabled (not .Values.workflowPersistence.existingClaim) }}
{{- true }}
{{- end }}
{{- end }}
