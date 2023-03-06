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
