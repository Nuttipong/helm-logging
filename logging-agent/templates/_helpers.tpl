{{- define "logging-agent.fullname" -}}
    {{- if .Values.nameOverride.fullnameOverride -}}
        {{- .Values.nameOverride.fullnameOverride | trunc 63 | trimSuffix "-" -}}
    {{- else -}}
        {{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
    {{- end -}}
{{- end -}}