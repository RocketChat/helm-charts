{{/* vim: set filetype=helm: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "rocketchat.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "rocketchat.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "rocketchat.mongodb.fullname" -}}
{{- printf "%s-%s-headless" .Release.Name "mongodb" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "rocketchat.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "rocketchat.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "rocketchat.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Return the apiVersion of deployment.
*/}}
{{- define "deployment.apiVersion" -}}
{{- if semverCompare "<1.14-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "extensions/v1beta1" -}}
{{- else if semverCompare ">=1.14-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "apps/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Renders a value that contains template. 
Note: This function was lent from Bitnami Common Library Chart (cf. 
https://github.com/bitnami/charts/blob/master/bitnami/common/templates/_tplvalues.tpl)
Usage:
{{ include "common.tplvalues.render" ( dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "common.tplvalues.render" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}

{{/*Generate the MONGO_URL*/}}
{{- define "rocketchat.mongodb.url" }}
    {{- if .Values.externalMongodbUrl }}
        {{- print .Values.externalMongodbUrl }}
    {{- else }}
        {{- $service := include "rocketchat.mongodb.fullname" . }}
        {{- $user := required "usernames array must have at least one entry" (first .Values.mongodb.auth.usernames) }}
        {{- $password := required "passwords array must have at least one entry" (first .Values.mongodb.auth.passwords) }}
        {{- $database := required "databases array must have at least one entry" (first .Values.mongodb.auth.databases) }}
        {{- $port := .Values.mongodb.service.ports.mongodb }}
        {{- $rs := .Values.mongodb.replicaSetName }}
        {{- printf "mongodb://%s:%s@%s:%0.f/%s?replicaSet=%s" $user $password $service $port $database $rs }}
    {{- end }}
{{- end }}

{{/*Generate MONGO_OPLOG_URL*/}}
{{- define "rocketchat.mongodb.oplogUrl" }}
    {{- if .Values.externalMongodbOplogUrl }}
        {{- print .Values.externalMongodbOplogUrl }}
    {{- else }}
        {{- $service := include "rocketchat.mongodb.fullname" . }}
        {{- $user := .Values.mongodb.auth.rootUser }}
        {{- $password := required "root password must be provided" .Values.mongodb.auth.rootPassword }}
        {{- $port := .Values.mongodb.service.ports.mongodb }}
        {{- $rs := .Values.mongodb.replicaSetName }}
        {{- printf "mongodb://%s:%s@%s:%0.f/local?replicaSet=%s&authSource=admin" $user $password $service $port $rs }}
    {{- end }}
{{- end }}

{{/* TODO: fail if types of the following are not what is expected instead of silently ignoring */}}

{{/* Get correct tolerations */}}
{{- define "rocketchat.tolerations" -}}
{{- $name := .name -}}
{{- $tolerations := list -}}
{{- with .context }}
{{- if eq $name "meteor" }}
{{ $tolerations = .Values.tolerations }}
{{- else }}
{{ $tolerations = get (get .Values.microservices $name) "tolerations" }}
{{- end }}
{{- if (and (kindIs "slice" $tolerations) (gt (len $tolerations) 0)) }}
{{- toYaml $tolerations }}
{{- else if (and (kindIs "slice" .Values.global.tolerations) (gt (len .Values.global.tolerations) 0)) }}
{{- toYaml .Values.global.tolerations }}
{{- end }}
{{- end }}
{{- end -}}

{{/* Get correct annotations */}}
{{- define "rocketchat.annotations" -}}
{{- $name := .name -}}
{{- $annotations := dict -}}
{{- with .context }}
{{- if eq $name "meteor" }}
{{ $annotations = .Values.podAnnotations}}
{{- else }}
{{ $annotations = get (get .Values.microservices $name) "annotations" }}
{{- end }}
{{- if (and (kindIs "map" $annotations) (gt (len $annotations) 0)) }}
{{- toYaml $annotations}}
{{- else if (and (kindIs "map" .Values.global.annotations) (gt (keys .Values.global.annotations | len) 0)) }}
{{- toYaml .Values.global.annotations}}
{{- end }}
{{- end }}
{{- end -}}

{{/* Get correct nodeSelector */}}
{{- define "rocketchat.nodeSelector" -}}
{{- $name := .name -}}
{{- $nodeSelector := dict -}}
{{- with .context }}
{{- if eq $name "meteor" }}
{{ $nodeSelector = .Values.nodeSelector }}
{{- else }}
{{ $nodeSelector = get (get .Values.microservices $name) "nodeSelector" }}
{{- end }}
{{- if (and (kindIs "map" $nodeSelector) (gt (len $nodeSelector) 0)) }}
{{- toYaml $nodeSelector | indent 2 }}
{{- else if (and (kindIs "map" .Values.global.nodeSelector) (gt (keys .Values.global.nodeSelector | len) 0)) }}
{{- toYaml .Values.global.nodeSelector | indent 2 }}
{{- end }}
{{- end }}
{{- end -}}

{{/* Get correct nodeAffinity */}}
{{- define "rocketchat.nodeAffinity" -}}
{{- $name := .name -}}
{{- $nodeAffinity := dict -}}
{{- with .context }}
{{- if eq $name "meteor" }}
{{ $nodeAffinity = .Values.affinity }}
{{- else }}
{{ $nodeAffinity = get (get .Values.microservices $name) "affinity" }}
{{- end }}
{{- if (and (kindIs "map" $nodeAffinity) (gt (len $nodeAffinity) 0)) }}
{{- toYaml $nodeAffinity | indent 8 }}
{{- else if (and (kindIs "map" .Values.global.affinity) (gt (keys .Values.global.affinity | len) 0)) }}
{{- toYaml .Values.global.affinity | indent 8 }}
{{- end }}
{{- end }}
{{- end -}}


{{/* Nats */}}
{{- define "rocketchat.transporter.connectionString" -}}
{{/*
One of the following must be true to set the TRANSPORTER environment variable:
1. If running microservices, and nats.enabled is not set, then we have deployed it
2. If nats.enabled is true, then we have deployed it
3. If nats.existingSecret is set, then we are using an external NATS server
*/}}
{{- if
    or
        (and (hasKey .Values.microservices "enabled") (.Values.microservices.enabled) (not (hasKey .Values.nats "enabled")))
        (and (hasKey .Values.nats "enabled") (.Values.nats.enabled))
        (and (hasKey .Values.nats "existingSecret") (not (empty .Values.nats.existingSecret)))
-}}
{{- if (hasKey .Values.nats "existingSecret") }}
- name: TRANSPORTER
  valueFrom:
    secretKeyRef:
      name: {{ .Values.nats.existingSecret.name }}
      key: {{ .Values.nats.existingSecret.key }}
{{- else }}
{{/* Determine protocol to use */}}
{{- $natsProtocol := "monolith+nats" -}}
{{- if and (hasKey .Values.microservices "enabled") (.Values.microservices.enabled) -}}
{{- $natsProtocol = "nats" -}}
{{- end -}}
- name: TRANSPORTER
  value: "{{ $natsProtocol }}://{{ .Release.Name }}-nats:4222"

{{- end -}}
{{- end -}} {{/* End if Nats enabled */}}
{{- end -}} {{/* rocketchat.transporter.connectionString */}}

{{/* 
Check if streamHub should be enabled.
Logic:
1. If explicitly set (.Values.microservices.streamHub.enabled), use that value
2. For versions < 7.7.3, enable by default
3. For versions >= 7.7.3, disable by default
*/}}
{{- define "rocketchat.streamHub.enabled" -}}
{{- $version := .Values.image.tag | default .Chart.AppVersion -}}
{{- $explicitlySet := hasKey .Values.microservices.streamHub "enabled" -}}
{{- if $explicitlySet -}}
{{- .Values.microservices.streamHub.enabled -}}
{{- else -}}
{{- if semverCompare "<7.7.3" $version -}}
{{- print "true" -}}
{{- else -}}
{{- print "false" -}}
{{- end -}}
{{- end -}}
{{- end -}}
