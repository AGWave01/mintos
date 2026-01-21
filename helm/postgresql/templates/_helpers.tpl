{{- define "postgresql.name" -}}
postgresql
{{- end -}}

{{- define "postgresql.fullname" -}}
{{- if .Release.Name -}}
{{- .Release.Name -}}
{{- else -}}
postgresql
{{- end -}}
{{- end -}}
