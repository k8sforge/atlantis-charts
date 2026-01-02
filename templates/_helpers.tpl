{{/*
Expand the name of the chart.
*/}}
{{- define "atlantis.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "atlantis.fullname" -}}
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
{{- define "atlantis.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "atlantis.labels" -}}
helm.sh/chart: {{ include "atlantis.chart" . }}
{{ include "atlantis.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.labels }}
{{- toYaml . | nindent 0 }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "atlantis.selectorLabels" -}}
app.kubernetes.io/name: {{ include "atlantis.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Pod template (shared between Deployment and Rollout)
*/}}
{{- define "atlantis.podTemplate" -}}
metadata:
  labels:
    {{- include "atlantis.selectorLabels" . | nindent 4 }}
spec:
  containers:
    - name: atlantis
      image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
      imagePullPolicy: {{ .Values.image.pullPolicy }}
      ports:
        - containerPort: 4141
          name: http
      env:
        - name: ATLANTIS_DATA_DIR
          value: {{ .Values.atlantis.dataDir | quote }}
        - name: ATLANTIS_REPO_ALLOWLIST
          valueFrom:
            configMapKeyRef:
              name: {{ include "atlantis.fullname" . }}-config
              key: repo-allowlist
        - name: ATLANTIS_REPO_CONFIG_JSON
          valueFrom:
            configMapKeyRef:
              name: {{ include "atlantis.fullname" . }}-config
              key: repo-config.json
        {{- if .Values.github.user }}
        - name: ATLANTIS_GH_USER
          valueFrom:
            secretKeyRef:
              name: {{ include "atlantis.fullname" . }}-secrets
              key: github-user
        {{- end }}
        {{- if .Values.github.token }}
        - name: ATLANTIS_GH_TOKEN
          valueFrom:
            secretKeyRef:
              name: {{ include "atlantis.fullname" . }}-secrets
              key: github-token
        {{- end }}
        {{- if .Values.github.app.id }}
        - name: ATLANTIS_GH_APP_ID
          valueFrom:
            secretKeyRef:
              name: {{ include "atlantis.fullname" . }}-secrets
              key: github-app-id
        - name: ATLANTIS_GH_APP_KEY_FILE
          value: "/atlantis-data/github-app-key.pem"
        {{- end }}
        {{- if .Values.github.app.installationId }}
        - name: ATLANTIS_GH_APP_INSTALLATION_ID
          valueFrom:
            secretKeyRef:
              name: {{ include "atlantis.fullname" . }}-secrets
              key: github-app-installation-id
        {{- end }}
        {{- if .Values.github.webhookSecret }}
        - name: ATLANTIS_GH_WEBHOOK_SECRET
          valueFrom:
            secretKeyRef:
              name: {{ include "atlantis.fullname" . }}-secrets
              key: webhook-secret
        {{- end }}
        - name: ATLANTIS_CHECKOUT_STRATEGY
          value: {{ .Values.atlantis.checkoutStrategy | quote }}
      volumeMounts:
        - name: atlantis-data
          mountPath: /atlantis-data
        {{- if .Values.github.app.key }}
        - name: github-app-key
          mountPath: /atlantis-data/github-app-key.pem
          subPath: github-app-key.pem
          readOnly: true
        {{- end }}
      resources:
        {{- toYaml .Values.resources | nindent 8 }}
      {{- if .Values.livenessProbe }}
      livenessProbe:
        {{- toYaml .Values.livenessProbe | nindent 8 }}
      {{- end }}
      {{- if .Values.readinessProbe }}
      readinessProbe:
        {{- toYaml .Values.readinessProbe | nindent 8 }}
      {{- end }}
  volumes:
    - name: atlantis-data
      emptyDir: {}
    {{- if .Values.github.app.key }}
    - name: github-app-key
      secret:
        secretName: {{ include "atlantis.fullname" . }}-secrets
        items:
          - key: github-app-key
            path: github-app-key.pem
    {{- end }}
{{- end }}

