{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}

{{- define "template.fullname" -}}
  {{- if .Values.ProjectName -}}
{{- .Values.ProjectName -}}
  {{- else }}
{{- .Release.Name  | trim -}}
  {{- end }}
{{- end }}

{{/*
Print vars {{- include "magda.var_dump" .name }}
*/}}
{{- define "magda.var_dump" -}}
{{- . | mustToPrettyJson | printf "\nThe JSON output of the dumped var is: \n%s" | fail }}
{{- end -}}

{{/*
Create the secret name, depending whether it is defined or not.
*/}}
{{- define "rabbit.secretname" -}}
{{- if .Values.rabbitmq.secretName }}
{{- .Values.rabbitmq.secretName | trim  -}}-admin
{{- else }}
{{- .Release.Name | trim -}}-admin
{{- end }}
{{- end }}


{{/*
COMMON Templates for the helm
*/}}

{{/*
Environment Variables  {{- include "template.environment" . | indent 2 }}
*/}}
{{- define "template.environment"}}
{{- if .env }}
- env:
  - name: MANAGEMENT_ENDPOINT_HEALTH_GROUP_LIVENESS_INCLUDE
    value: livenessState,livenessProbe
  - name: MANAGEMENT_ENDPOINT_HEALTH_GROUP_READINESS_INCLUDE
    value: readinessState,readinessProbe
  - name: MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE
    value: health,info,metrics,prometheus
  - name: MANAGEMENT_HEALTH_LIVENESSSTATE_ENABLED
    value: "'true'"
  - name: MANAGEMENT_HEALTH_READINESSSTATE_ENABLED
    value: "'true'"
  {{- range .env }}
  - name: {{ .name }}
    {{- if .valueFrom}}
    valueFrom:
      secretKeyRef:
        key: {{ .valueFrom.secretKeyRef.key }}
        name: {{ .valueFrom.secretKeyRef.name }}
    {{- end }}
    {{- if .value }}
    value: {{ .value }}
    {{- end }}
{{- end }}
{{- else }}
- env: []
{{- end }}
{{- end }}


{{/*
Ports {{- include "template.ports" . | indent 2}}
*/}}
{{- define "template.ports" }}
{{- with .ports  }}
ports:
{{- range . }}

  {{- if .port }}
  - port: {{ .port }}

    {{- if .containerPort }}
    containerPort: {{ .containerPort }}
    {{- end }}

  {{- else }}
    {{- if .containerPort }}
  - containerPort: {{ .containerPort }}
    {{- end }}
  {{- end }}

    {{- if .name }}
    name: {{ .name }}
    {{- end }}

    {{- if .protocol }}
    protocol: {{ .protocol }}
    {{- end }}

    {{- if .targetPort }}
    targetPort: {{ .targetPort }}
    {{- end }}

{{- end }}
{{- end }}
{{- end }}


{{/*
Labels {{- include "template.labels" . | indent 2}}
INPUT: { . , somevalue }
*/}}
{{- define "template.labels" }}
labels:
  app: {{ .root.name | default .name }}
  version: {{ .root.version | default "v1" }}
{{- with .root.labels }}
  {{- range $key, $value := . }}
  {{ $key }}: {{ $value }}
  {{- end }}
{{- end }}
{{- end }}


{{/*
Volumes {{- include "template.volumes" . | indent 2}}
*/}}
{{- define "template.volumes" }}
{{- with .volumes  }}
volumes:
{{- range . }}
  {{- if .hostPath }}
  - hostPath:
      path: {{ .hostPath.path }}
      type: ""
    name: {{ .name }}
  {{- else }}
  {{- if .persistentVolumeClaim }}
  - persistentVolumeClaim:
      claimName: {{ .persistentVolumeClaim.claimName }}
    name: {{ .name }}
  {{- else }}
  {{- if .configMap }}
  - configMap:
      {{- if .defaultMode }}
      defaultMode:  {{ .configMap.defaultMode }}
      {{- end }}
    {{- with .configMap }}
      {{- with .items }}
      items:
      {{- range . }}
      - key: {{ .key }}
        path:  {{ .path }}
      {{- end }}
      {{- end }}
      name:  {{ .name }}
      optional: false
    {{- end }}
    name:  {{ .name }}
  {{- else }}
  - emptyDir: {}
    name: {{ .name }}
  {{- end }}
  {{- end }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
volumeMounts {{- include "template.volumeMounts" . }}
*/}}
{{- define "template.volumeMounts" }}
{{- with .volumeMounts  }}
volumeMounts:
{{- range . }}
  - mountPath: {{ .mountPath }}
    name: {{ .name }}
{{- end }}
{{- end }} 
{{- end }}



{{/*
securityContext {{- include "template.securityContext" . }}
*/}}
{{- define "template.securityContext" }}
{{- with .securityContext }}
securityContext:
  {{- if .allowPrivilegeEscalation }}
  allowPrivilegeEscalation: {{ .allowPrivilegeEscalation }}
  {{- end }}
  {{- if .fsGroup }}
  fsGroup: {{ .fsGroup }}
  supplementalGroups:
  -  {{ .fsGroup }}
  {{- end }}
  {{- if .runAsUser }}
  runAsUser: {{ .runAsUser }}
  {{- end }}
  {{- if .privileged }}
  privileged: {{ .privileged }}
  {{- end }}
  {{- with .capabilities }}
  capabilities:
    {{- if .drop }}
    drop:
    - ALL
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}


{{/*
livenessProbe {{- include "template.livenessProbe" . | indent 6 }}
*/}}
{{- define "template.livenessProbe" }}

{{- with .livenessProbe }}
livenessProbe:

  {{- with .httpGet }}
  httpGet:
    path: {{ .path }}
    port: {{ .port }}
    {{- with .httpHeaders}}
    httpHeaders:
    {{- range . }}
    - name: {{ .name }}
      value: {{ .value }}
    {{- end }}
    {{- end }}
  {{- end }}

  {{- with .tcpSocket }}
  tcpSocket:
    port: {{ .port }}
  {{- end }}

  {{- with .grpc }}
  grpc:
    port: {{ .port }}
  {{- end }}

  {{- with .command }}
  exec:
    command:
    {{- range . }}
      - {{.}}
    {{- end }}
  {{- end }}

  {{- if .failureThreshold }}
  failureThreshold: {{ .failureThreshold }}
  {{- end }}
  {{- if .initialDelaySeconds }}
  initialDelaySeconds: {{ .initialDelaySeconds }}
  {{- end }}
  {{- if .periodSeconds }}
  periodSeconds: {{ .periodSeconds }}
  {{- end }}
  {{- if .successThreshold }}
  successThreshold: {{ .successThreshold }}
  {{- end }}
  {{- if .timeoutSeconds }}
  timeoutSeconds: {{ .timeoutSeconds }}
  {{- end }}
{{- end }}

{{- end }}

{{/*
startupProbe {{- include "template.startupProbe" . | indent 6 }}
*/}}
{{- define "template.startupProbe" }}

{{- with .startupProbe }}
startupProbe:

  {{- with .httpGet }}
  httpGet:
    path: {{ .path }}
    port: {{ .port }}
    {{- with .httpHeaders}}
    httpHeaders:
    {{- range . }}
    - name: {{ .name }}
      value: {{ .value }}
    {{- end }}
    {{- end }}
  {{- end }}

  {{- with .tcpSocket }}
  tcpSocket:
    port: {{ .port }}
  {{- end }}

  {{- with .grpc }}
  grpc:
    port: {{ .port }}
  {{- end }}

  {{- with .command }}
  exec:
    command:
    {{- range . }}
      - {{.}}
    {{- end }}
  {{- end }}

  {{- if .failureThreshold }}
  failureThreshold: {{ .failureThreshold }}
  {{- end }}
  {{- if .initialDelaySeconds }}
  initialDelaySeconds: {{ .initialDelaySeconds }}
  {{- end }}
  {{- if .periodSeconds }}
  periodSeconds: {{ .periodSeconds }}
  {{- end }}
  {{- if .successThreshold }}
  successThreshold: {{ .successThreshold }}
  {{- end }}
  {{- if .timeoutSeconds }}
  timeoutSeconds: {{ .timeoutSeconds }}
  {{- end }}
{{- end }}

{{- end }}

{{/*
readinessProbe {{- include "template.readinessProbe" . | indent 6 }}
*/}}
{{- define "template.readinessProbe" }}

{{- with .readinessProbe }}
readinessProbe:

  {{- with .httpGet }}
  httpGet:
    path: {{ .path }}
    port: {{ .port }}
    {{- with .httpHeaders}}
    httpHeaders:
    {{- range . }}
    - name: {{ .name }}
      value: {{ .value }}
    {{- end }}
    {{- end }}
  {{- end }}

  {{- with .tcpSocket }}
  tcpSocket:
    port: {{ .port }}
  {{- end }}

  {{- with .grpc }}
  grpc:
    port: {{ .port }}
  {{- end }}

  {{- with .command }}
  exec:
    command:
    {{- range . }}
      - {{.}}
    {{- end }}
  {{- end }}

  {{- if .failureThreshold }}
  failureThreshold: {{ .failureThreshold }}
  {{- end }}
  {{- if .initialDelaySeconds }}
  initialDelaySeconds: {{ .initialDelaySeconds }}
  {{- end }}
  {{- if .periodSeconds }}
  periodSeconds: {{ .periodSeconds }}
  {{- end }}
  {{- if .successThreshold }}
  successThreshold: {{ .successThreshold }}
  {{- end }}
  {{- if .timeoutSeconds }}
  timeoutSeconds: {{ .timeoutSeconds }}
  {{- end }}
{{- end }}

{{- end }}