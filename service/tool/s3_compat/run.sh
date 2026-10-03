#!/usr/bin/env bash
# Pruebas de compatibilidad contra un feather-io ya arrancado, con clientes S3
# reales en Docker. Uso (desde cualquier carpeta):
#
#   service/tool/s3_compat/run.sh [awscli|rclone|mint ...]
#
# Sin argumentos ejecuta awscli y rclone. Variables (con sus valores por defecto):
#   ENDPOINT=http://host.docker.internal:8080   (el servicio visto desde Docker)
#   ACCESS_KEY=access  SECRET_KEY=secret         (FEATHER_ACCESS / FEATHER_SECRET)
#   MINT_SUITES="awscli aws-sdk-go ..."          (suites de Mint; ver README)
set -u

DIR=$(cd "$(dirname "$0")" && pwd)
ENDPOINT=${ENDPOINT:-http://host.docker.internal:8080}
ACCESS_KEY=${ACCESS_KEY:-access}
SECRET_KEY=${SECRET_KEY:-secret}
MINT_SUITES=${MINT_SUITES:-"awscli aws-sdk-go aws-sdk-java aws-sdk-java-v2 aws-sdk-php aws-sdk-ruby minio-go minio-py minio-js minio-java mc s3cmd"}

# en Git Bash (Windows) las rutas de los volumenes no se deben convertir
export MSYS_NO_PATHCONV=1
host_dir=$DIR
command -v cygpath >/dev/null && host_dir=$(cygpath -w "$DIR")

env_args=(-e "ENDPOINT=$ENDPOINT" -e "AWS_ACCESS_KEY_ID=$ACCESS_KEY" -e "AWS_SECRET_ACCESS_KEY=$SECRET_KEY")
status=0

run_awscli() {
  docker run --rm "${env_args[@]}" -v "$host_dir:/compat:ro" \
    --entrypoint bash amazon/aws-cli /compat/awscli.sh || status=1
}

run_rclone() {
  docker run --rm "${env_args[@]}" -v "$host_dir:/compat:ro" \
    --entrypoint sh rclone/rclone /compat/rclone.sh || status=1
}

run_mint() {
  # Mint espera host:puerto, sin esquema
  local server=${ENDPOINT#*://}
  # shellcheck disable=SC2086
  docker run --rm -e SERVER_ENDPOINT="$server" -e ACCESS_KEY="$ACCESS_KEY" \
    -e SECRET_KEY="$SECRET_KEY" -e ENABLE_HTTPS=0 -e MINT_MODE=core -e RUN_ON_FAIL=1 \
    minio/mint:latest $MINT_SUITES || status=1
}

targets=("$@")
[ ${#targets[@]} -eq 0 ] && targets=(awscli rclone)
for target in "${targets[@]}"; do
  echo "===== $target ====="
  case $target in
    awscli) run_awscli ;;
    rclone) run_rclone ;;
    mint) run_mint ;;
    *) echo "Desconocido: $target (awscli, rclone o mint)"; status=1 ;;
  esac
  echo
done
exit $status
