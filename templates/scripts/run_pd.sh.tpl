#!/bin/bash
set -e

# WARNING: This file was auto-generated. Do not edit!
#          All your edit might be overwritten!
DEPLOY_DIR={{.DeployDir}}

cd "${DEPLOY_DIR}" || exit 1

{{- define "PDList"}}
  {{- range $idx, $pd := .}}
    {{- if eq $idx 0}}
      {{- $pd.Name}}={{$pd.Scheme}}://{{$pd.IP}}:{{$pd.PeerPort}}
    {{- else -}}
      ,{{- $pd.Name}}={{$pd.Scheme}}://{{$pd.IP}}:{{$pd.PeerPort}}
    {{- end}}
  {{- end}}
{{- end}}

{{- if .NumaNode}}
exec numactl --cpunodebind={{.NumaNode}} --membind={{.NumaNode}} bin/pd-server \
{{- else}}
exec bin/pd-server \
{{- end}}
    --name="{{.Name}}" \
    --client-urls="{{.Scheme}}://{{.IP}}:{{.ClientPort}}" \
    --advertise-client-urls="{{.Scheme}}://{{.IP}}:{{.ClientPort}}" \
    --peer-urls="{{.Scheme}}://{{.IP}}:{{.PeerPort}}" \
    --advertise-peer-urls="{{.Scheme}}://{{.IP}}:{{.PeerPort}}" \
    --data-dir="{{.DataDir}}" \
    --initial-cluster="{{template "PDList" .Endpoints}}" \
    --log-file="logs/pd.log" 2>> "logs/pd_stderr.log"
  