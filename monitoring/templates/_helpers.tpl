{{/*
Expand the name of the chart.
*/}}
{{- define "monitoring.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "monitoring.fullname" -}}
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
{{- define "monitoring.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "monitoring.labels" -}}
helm.sh/chart: {{ include "monitoring.chart" . }}
{{ include "monitoring.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "monitoring.selectorLabels" -}}
app.kubernetes.io/name: {{ include "monitoring.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "monitoring.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "monitoring.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/* Get correct tolerations */}}
{{- define "monitoring.tolerations" -}}
{{- $name := .name -}}
{{- $tolerations := list -}}
{{- with .context }}
{{- if and $name (hasKey .Values $name) }}
{{- $component := get .Values $name }}
{{- if and (hasKey $component "tolerations") (kindIs "slice" $component.tolerations) (gt (len $component.tolerations) 0) }}
{{- $tolerations = $component.tolerations }}
{{- end }}
{{- end }}
{{- if (and (kindIs "slice" $tolerations) (gt (len $tolerations) 0)) }}
{{- toYaml $tolerations }}
{{- else if (and (kindIs "slice" .Values.global.tolerations) (gt (len .Values.global.tolerations) 0)) }}
{{- toYaml .Values.global.tolerations }}
{{- end }}
{{- end }}
{{- end -}}

{{/* Get correct nodeSelector */}}
{{- define "monitoring.nodeSelector" -}}
{{- $name := .name -}}
{{- $nodeSelector := dict -}}
{{- with .context }}
{{- if and $name (hasKey .Values $name) }}
{{- $component := get .Values $name }}
{{- if and (hasKey $component "nodeSelector") (kindIs "map" $component.nodeSelector) (gt (len $component.nodeSelector) 0) }}
{{- $nodeSelector = $component.nodeSelector }}
{{- end }}
{{- end }}
{{- if (and (kindIs "map" $nodeSelector) (gt (len $nodeSelector) 0)) }}
{{- toYaml $nodeSelector }}
{{- else if (and (kindIs "map" .Values.global.nodeSelector) (gt (keys .Values.global.nodeSelector | len) 0)) }}
{{- toYaml .Values.global.nodeSelector }}
{{- end }}
{{- end }}
{{- end -}}

{{/* Get correct affinity */}}
{{- define "monitoring.affinity" -}}
{{- $name := .name -}}
{{- $affinity := dict -}}
{{- with .context }}
{{- if and $name (hasKey .Values $name) }}
{{- $component := get .Values $name }}
{{- if and (hasKey $component "affinity") (kindIs "map" $component.affinity) (gt (len $component.affinity) 0) }}
{{- $affinity = $component.affinity }}
{{- end }}
{{- end }}
{{- if (and (kindIs "map" $affinity) (gt (len $affinity) 0)) }}
{{- toYaml $affinity }}
{{- else if (and (kindIs "map" .Values.global.affinity) (gt (keys .Values.global.affinity | len) 0)) }}
{{- toYaml .Values.global.affinity }}
{{- end }}
{{- end }}
{{- end -}}

