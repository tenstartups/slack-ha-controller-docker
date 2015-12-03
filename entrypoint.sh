#!/bin/bash
set -e

WEBHOOK_CONFIG="${WEBHOOK_CONFIG:-/etc/webhook/hooks.json}"

ruby -e "require 'configuration'; Configuration.instance"

# Look for known command aliases
case "$1" in
  "webhook" ) exec webhook -hooks "${WEBHOOK_CONFIG}" --verbose ;;
  *         ) exec "$@" ;;
esac
