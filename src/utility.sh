#!/bin/bash
# Utility function

# To highlight logs
log() {
  echo -e "\e[34m$(date '+%Y-%m-%d %H:%M:%S') $1 $2\e[0m"
}
