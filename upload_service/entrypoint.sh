#!/bin/bash
set -e

# Remove arquivo de PID do Rails
rm -f /app/tmp/pids/server.pid

# Executa o comando padrão (como rails server ou db:create)
exec "$@"
