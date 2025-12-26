#!/usr/bin/env sh
# Supported shells are bash and ash, we don't aim for POSIX compatibility

set -euo pipefail

if [[ -n "${MEMORY_LIMIT+$MEMORY_LIMIT}" ]]; then
   MAX_OLD_SPACE_SIZE=$((MEMORY_LIMIT * 8 / 10 / 1024 / 1024))
fi

node ${MAX_OLD_SPACE_SIZE+--max-old-space-size=$MAX_OLD_SPACE_SIZE} dist/src/index.js ${CONFIG_FILE+$CONFIG_FILE}
