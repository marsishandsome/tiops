---
global:
  scrape_interval:     15s # By default, scrape targets every 15 seconds.
  evaluation_interval: 15s # By default, scrape targets every 15 seconds.
  # scrape_timeout is set to the global default (10s).
  external_labels:
    cluster: '{{.ClusterName}}'
    monitor: "prometheus"

# Load and evaluate rules in this file every 'evaluation_interval' seconds.
rule_files:
  - 'node.rules.yml'
  - 'blacker.rules.yml'
  - 'bypass.rules.yml'
  - 'pd.rules.yml'
  - 'tidb.rules.yml'
  - 'tikv.rules.yml'
  - 'tikv.accelerate.rules.yml'
{{- if .PumpAddrs}}
  - 'binlog.rules.yml'
{{- end}}
{{- if .KafkaAddrs}}
  - 'kafka.rules.yml'
{{- end}}
{{- if .LightningAddrs}}
  - 'lightning.rules.yml'
{{- end}}

{{- if .AlertmanagerAddr}}
alerting:
 alertmanagers:
 - static_configs:
   - targets:
     - '{{.AlertmanagerAddr}}'
{{- end}}

scrape_configs:
{{- if .PushgatewayAddr}}
  - job_name: 'overwritten-cluster'
    scrape_interval: 15s
    honor_labels: true # don't overwrite job & instance labels
    static_configs:
      - targets: ['{{.PushgatewayAddr}}']

  - job_name: "blackbox_exporter_http"
    scrape_interval: 30s
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
    - targets:
      - 'http://{{.PushgatewayAddr}}/metrics'
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: {{.BlackboxAddr}}
{{- end}}
{{- if .LightningAddrs}}
  - job_name: "lightning"
    static_configs:
      - targets: ['{{index .LightningAddrs 0}}']
{{- end}}
  - job_name: "overwritten-nodes"
    honor_labels: true # don't overwrite job & instance labels
    static_configs:
    - targets:
{{- range .NodeExporterAddrs}}
      - '{{.}}'
{{- end}}
  - job_name: "tidb"
    honor_labels: true # don't overwrite job & instance labels
    static_configs:
    - targets:
{{- range .TiDBStatusAddrs}}
      - '{{.}}'
{{- end}}
  - job_name: "tikv"
    honor_labels: true # don't overwrite job & instance labels
    static_configs:
    - targets:
{{- range .TiKVStatusAddrs}}
      - '{{.}}'
{{- end}}
  - job_name: "pd"
    honor_labels: true # don't overwrite job & instance labels
    static_configs:
    - targets:
{{- range .PDAddrs}}
      - '{{.}}'
{{- end}}
{{- if .PumpAddrs}}
{{- if .KafkaExporterAddr}}
  - job_name: 'kafka_exporter'
    honor_labels: true # don't overwrite job & instance labels
    static_configs:
    - targets:
      - '{{.KafkaExporterAddr}}'
{{- end}}
  - job_name: 'pump'
    honor_labels: true # don't overwrite job & instance labels
    static_configs:
    - targets:
    {{- range .PumpAddrs}}
      - '{{.}}'
    {{- end}}
  - job_name: 'drainer'
    honor_labels: true # don't overwrite job & instance labels
    static_configs:
    - targets:
    {{- range .DrainerAddrs}}
      - '{{.}}'
    {{- end}}
  - job_name: "port_probe"
    scrape_interval: 30s
    metrics_path: /probe
    params:
      module: [tcp_connect]
    static_configs:
{{- if .KafkaAddrs}}
    - targets:
    {{- range .KafkaAddrs}}
        - '{{.}}'
    {{- end}}
      labels:
        group: 'kafka'
{{- end}}
{{- if .ZookeeperAddrs}}
    - targets:
    {{- range .ZookeeperAddrs}}
      - '{{.}}'
    {{- end}}
      labels:
        group: 'zookeeper'
{{- end}}
    - targets:
{{- range .PumpAddrs}}
      - '{{.}}'
{{- end}}
      labels:
        group: 'pump'
    - targets:
    {{- range .DrainerAddrs}}
      - '{{.}}'
    {{- end}}
      labels:
        group: 'drainer'
{{- if .KafkaExporterAddr}}
    - targets:
      - '{{.KafkaExporterAddr}}'
      labels:
        group: 'kafka_exporter'
{{- end}}
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: {{.BlackboxAddr}}
{{- end}}
  - job_name: "tidb_port_probe"
    scrape_interval: 30s
    metrics_path: /probe
    params:
      module: [tcp_connect]
    static_configs:
    - targets:
    {{- range .TiDBStatusAddrs}}
      - '{{.}}' 
    {{- end}}
      labels:
        group: 'tidb'
    - targets:
    {{- range .TiKVStatusAddrs}}
      - '{{.}}'
    {{- end}}
      labels:
        group: 'tikv'
    - targets:
    {{- range .PDAddrs}}
      - '{{.}}'
    {{- end}}
      labels:
        group: 'pd'
    - targets:
      - '{{.PushgatewayAddr}}'
      labels:
        group: 'pushgateway'
    - targets:
      - '{{.GrafanaAddr}}'
      labels:
        group: 'grafana'
    - targets:
    {{- range .NodeExporterAddrs}}
      - '{{.}}'
    {{- end}}
      labels:
        group: 'node_exporter'
    - targets:
    {{- range .BlackboxExporterAddrs}}
      - '{{.}}'
    {{- end}}
      labels:
        group: 'blackbox_exporter'
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: {{.BlackboxAddr}}
{{- range $addr := .BlackboxExporterAddrs}}
  - job_name: "blackbox_exporter_{{$addr}}_icmp"
    scrape_interval: 6s
    metrics_path: /probe
    params:
      module: [icmp]
    static_configs:
    - targets:
    {{- range .MonitoredServers}}
      - '{{.}}'
    {{- end}}
    relabel_configs:
      - source_labels: [__address__]
        regex: (.*)(:80)?
        target_label: __param_target
        replacement: ${1}
      - source_labels: [__param_target]
        regex: (.*)
        target_label: ping
        replacement: ${1}
      - source_labels: []
        regex: .*
        target_label: __address__
        replacement: {{$addr}}
{{- end}}