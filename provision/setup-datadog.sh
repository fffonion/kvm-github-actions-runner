#!/bin/bash

# wget
# update bind_host to bridge
sed -i.bak  's/.*logs_enabled:.*/logs_enabled: true/g' /etc/datadog-agent/datadog.yaml
cat << EOF > /etc/datadog-agent/conf.d/self-hosted.yml
logs:
  - type: udp
    port: 10518
    service: "self_hosted_runner"
    source: "self_hosted_runner"
EOF
systemctl restart datadog-agent
