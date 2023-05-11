#!/bin/bash

# wget
# update bind_host to bridge
sed -i.bak 's/.*bind_host:.*/bind_host: 10.1.0.1/' /etc/datadog-agent/datadog.yaml
sed -i.bak 's/.*logs_enabled:.*/logs_enabled: true/' /etc/datadog-agent/datadog.yaml
sed -i.bak 's/.*histogram_aggregates:.*/histogram_aggregates: ["max","medium","avg","count","sum"]/' /etc/datadog-agent/datadog.yaml

cat << EOF > /etc/datadog-agent/conf.d/self-hosted.yml
logs:
  - type: udp
    port: 10518
    service: "self_hosted_runner"
    source: "self_hosted_runner"
EOF
systemctl restart datadog-agent
