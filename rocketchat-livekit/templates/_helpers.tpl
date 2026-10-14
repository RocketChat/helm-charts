{{/*
Expand the name of the chart.
*/}}
{{- define "rocketchat-livekit.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "rocketchat-livekit.fullname" -}}
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
{{- define "rocketchat-livekit.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "rocketchat-livekit.labels" -}}
helm.sh/chart: {{ include "rocketchat-livekit.chart" . }}
{{ include "rocketchat-livekit.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "rocketchat-livekit.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rocketchat-livekit.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "rocketchat-livekit.serviceAccountName" -}}
{{- if eq (include "rocketchat-livekit.isTrue" .Values.serviceAccount.create) "true" }}
{{- default (include "rocketchat-livekit.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Truthiness that survives launchcontrol, which hands every value over as a
string: "false" is a non-empty string, and as such, true for `if`.
Usage: {{ if eq (include "rocketchat-livekit.isTrue" .Values.foo) "true" }}
*/}}
{{- define "rocketchat-livekit.isTrue" -}}
{{- if kindIs "string" . }}
{{- eq (lower (trim .)) "true" }}
{{- else }}
{{- not (not .) }}
{{- end }}
{{- end }}

{{/*
Public host of the signalling endpoint.
*/}}
{{- define "rocketchat-livekit.host" -}}
{{- tpl .Values.host . }}
{{- end }}

{{/*
Name of the Secret holding the API key pair.
*/}}
{{- define "rocketchat-livekit.credentialsSecretName" -}}
{{- .Values.credentials.existingSecret | default .Values.credentials.secretName }}
{{- end }}

{{/*
Whether the media Service is a load balancer (as opposed to a NodePort).
*/}}
{{- define "rocketchat-livekit.mediaIsLoadBalancer" -}}
{{- has .Values.media.serviceType (list "nlb" "LoadBalancer") }}
{{- end }}

{{/*
Host of the TURN relay.
*/}}
{{- define "rocketchat-livekit.turnHost" -}}
{{- tpl (.Values.turn.host | default .Values.media.externalAddress) . }}
{{- end }}

{{/*
Name of the TLS Secret used by the TURN relay.
*/}}
{{- define "rocketchat-livekit.turnTlsSecretName" -}}
{{- .Values.turn.existingTlsSecret | default (printf "%s-turn-tls" (include "rocketchat-livekit.fullname" .)) }}
{{- end }}

{{/*
livekit.yaml. The API keys and the advertised IP are passed as environment
variables instead, so this can live in a ConfigMap.
*/}}
{{- define "rocketchat-livekit.config" -}}
{{- $nodeIP := tpl .Values.media.nodeIP . }}
{{- $externalAddress := tpl .Values.media.externalAddress . }}
{{- $rtc := dict
  "udp_port" (.Values.media.udpPort | int)
  "tcp_port" 0
  "use_external_ip" (and (empty $nodeIP) (empty $externalAddress))
}}
{{- /* Don't advertise ICE/TCP candidates nobody can reach. */}}
{{- if eq (include "rocketchat-livekit.isTrue" .Values.media.tcp.enabled) "true" }}
{{- $_ := set $rtc "tcp_port" (.Values.media.tcp.port | int) }}
{{- end }}
{{- with .Values.media.stunServers }}
{{- $_ := set $rtc "stun_servers" . }}
{{- end }}
{{- $config := dict
  "port" 7880
  "rtc" $rtc
  "logging" (dict "level" .Values.logLevel)
}}
{{- if eq (include "rocketchat-livekit.isTrue" .Values.monitoring.prometheus.enabled) "true" }}
{{- $_ := set $config "prometheus" (dict "port" (.Values.monitoring.prometheus.port | int)) }}
{{- end }}
{{- if eq (include "rocketchat-livekit.isTrue" .Values.turn.enabled) "true" }}
{{- $_ := set $config "turn" (dict
  "enabled" true
  "domain" (include "rocketchat-livekit.turnHost" .)
  "tls_port" (.Values.turn.tlsPort | int)
  "cert_file" "/etc/livekit/tls/tls.crt"
  "key_file" "/etc/livekit/tls/tls.key"
) }}
{{- end }}
{{- toYaml (mergeOverwrite $config (deepCopy (.Values.config | default dict))) }}
{{- end }}
