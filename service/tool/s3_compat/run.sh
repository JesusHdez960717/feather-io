#!/usr/bin/env bash
# Compatibility tests against a running feather-io, with real S3 clients in
# Docker. Usage (from any folder):
#
#   service/tool/s3_compat/run.sh [awscli|rclone|mint ...]
#
# Without arguments it runs awscli and rclone. Variables (with their defaults):
#   ENDPOINT=http://host.docker.internal:8080   (the service as seen from Docker)
#   ACCESS_KEY=access  SECRET_KEY=secret         (FEATHER_ACCESS / FEATHER_SECRET)
#   MINT_SUITES="awscli aws-sdk-go ..."          (Mint suites; see the README)
#   OUT_DIR=service/tool/s3_compat/out           (outputs for report.py; gitignored)
#
# Each target leaves its output in OUT_DIR (<target>.txt, plus Mint's
# mint-logs/log.json), which report.py reads to write RESULTS.md
set -u

DIR=$(cd "$(dirname "$0")" && pwd)
ENDPOINT=${ENDPOINT:-http://host.docker.internal:8080}
ACCESS_KEY=${ACCESS_KEY:-access}
SECRET_KEY=${SECRET_KEY:-secret}
MINT_SUITES=${MINT_SUITES:-"awscli aws-sdk-go aws-sdk-java aws-sdk-java-v2 aws-sdk-php aws-sdk-ruby minio-go minio-py minio-js minio-java mc s3cmd healthcheck s3select versioning"}
OUT_DIR=${OUT_DIR:-$DIR/out}
mkdir -p "$OUT_DIR"
OUT_DIR=$(cd "$OUT_DIR" && pwd)

# In Git Bash (Windows) the volume paths must not be converted
export MSYS_NO_PATHCONV=1
host_path() { if command -v cygpath >/dev/null; then cygpath -w "$1"; else echo "$1"; fi; }

env_args=(-e "ENDPOINT=$ENDPOINT" -e "AWS_ACCESS_KEY_ID=$ACCESS_KEY" -e "AWS_SECRET_ACCESS_KEY=$SECRET_KEY")
status=0

run_awscli() {
  docker run --rm "${env_args[@]}" -v "$(host_path "$DIR"):/compat:ro" \
    --entrypoint bash amazon/aws-cli /compat/awscli.sh
}

run_rclone() {
  docker run --rm "${env_args[@]}" -v "$(host_path "$DIR"):/compat:ro" \
    --entrypoint sh rclone/rclone /compat/rclone.sh
}

run_mint() {
  # Mint expects host:port, without a scheme
  local server=${ENDPOINT#*://}
  rm -rf "$OUT_DIR/mint-logs" && mkdir -p "$OUT_DIR/mint-logs"
  # shellcheck disable=SC2086
  docker run --rm -e SERVER_ENDPOINT="$server" -e ACCESS_KEY="$ACCESS_KEY" \
    -e SECRET_KEY="$SECRET_KEY" -e ENABLE_HTTPS=0 -e MINT_MODE=core -e RUN_ON_FAIL=1 \
    -v "$(host_path "$OUT_DIR/mint-logs"):/mint/log" \
    minio/mint:latest $MINT_SUITES
}

targets=("$@")
[ ${#targets[@]} -eq 0 ] && targets=(awscli rclone)
for target in "${targets[@]}"; do
  echo "===== $target ====="
  case $target in
    awscli | rclone | mint)
      "run_$target" 2>&1 | tee "$OUT_DIR/$target.txt"
      [ "${PIPESTATUS[0]}" -eq 0 ] || status=1
      ;;
    *) echo "Unknown target: $target (awscli, rclone or mint)"; status=1 ;;
  esac
  echo
done
exit $status
