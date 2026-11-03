# ELK Stack Instructions

## Components
- Elasticsearch — storage + search
- Logstash — log ingestion + transformation
- Kibana — visualization + dashboards
- Filebeat / Metricbeat — agents

## Common Commands
```bash
# Elasticsearch
curl -X GET "localhost:9200/_cluster/health"
curl -X GET "localhost:9200/_cat/indices?v"

# Kibana
curl localhost:5601/api/status

# Logstash
logstash -f pipeline.conf --config.test_and_exit

# Filebeat
filebeat test config
filebeat test output
```

## Docker Compose
```yaml
# Standard ELK stack: elasticsearch + logstash + kibana
# Version: 8.x with security enabled
# Memory: ES_HEAP_SIZE=1g minimum
```

## Conventions
- Use ILM (Index Lifecycle Management) for log rotation
- Index templates: define mappings + settings upfront
- Logstash pipelines: `input { beats { port => 5044 } }`
- Never use `_all` field (deprecated)
- Use `.env` for version numbers
- Security: enable TLS + basic auth

## Troubleshooting
```bash
# Red cluster
curl localhost:9200/_cluster/allocation/explain

# Slow queries
curl localhost:9200/_nodes/hot_threads

# Disk pressure
curl localhost:9200/_cat/allocation?v
```

## Verify
```bash
curl -s localhost:9200 | jq .version.number
```
