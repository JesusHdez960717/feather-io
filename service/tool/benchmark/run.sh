#!/usr/bin/env bash
# Performance of feather-io with MinIO's warp, both in Docker on Linux (the service runs from its
# own image), and the same scenarios against MinIO as a reference. Usage (from any folder):
#
#   service/tool/benchmark/run.sh [feather|minio|limited ...]
#
# Without arguments it runs feather and minio. `limited` runs a mixed load against the service with
# its default general rate limit (2000 requests/min per IP). Build the image first:
#   docker build -t feather-io service/
#
# Variables (with their defaults):
#   DURATION=20s                 how long each scenario runs
#   MINIO_IMAGE=elestio/minio:latest   the reference server
#   LIST_SIZES="100 1000 5000 10000"   objects in the bucket of each listing scenario
#   ONLY=regex                   run only the scenarios whose name matches, keeping the rest of
#                                the outputs (ONLY=list-flat run.sh feather minio)
#   OUT_DIR=service/tool/benchmark/out (outputs for report.py; gitignored)
#
# Each scenario leaves warp's summary in OUT_DIR/<target>/<scenario>.txt and the RSS of the
# server's process sampled every 2 s in <scenario>.mem (KiB); the listing ones also time ListBuckets
# (listbuckets.txt). report.py reads them to write RESULTS.md.
set -u

DIR=$(cd "$(dirname "$0")" && pwd)
DURATION=${DURATION:-20s}
LIST_SIZES=${LIST_SIZES:-"100 1000 5000 10000"}
ONLY=${ONLY:-}
OUT_DIR=${OUT_DIR:-$DIR/out}
mkdir -p "$OUT_DIR"
OUT_DIR=$(cd "$OUT_DIR" && pwd)

ACCESS=bench-access
SECRET=bench-secret-key
# Names of this run: two runs at once (or one left behind) never touch each other's containers
RUN=bench-$$
SERVER=$RUN-server
NETWORK=$RUN-net
WARP_IMAGE=minio/warp:latest
# MinIO no longer publishes its images on Docker Hub: Elestio's packaging of the same binary
MINIO_IMAGE=${MINIO_IMAGE:-elestio/minio:latest}

# In Git Bash (Windows) the paths given to docker must not be converted
export MSYS_NO_PATHCONV=1
host_path() { if command -v cygpath >/dev/null; then cygpath -w "$1"; else echo "$1"; fi; }

docker network create "$NETWORK" >/dev/null 2>&1

# On exit (or Ctrl+C) the containers and the network of this run go away
cleanup() {
  [ -n "${SAMPLER:-}" ] && kill "$SAMPLER" 2>/dev/null
  docker ps -aq --filter "label=$RUN" | xargs -r docker rm -fv >/dev/null 2>&1
  # The warp containers (--rm) may still be leaving the network
  for _ in 1 2 3 4 5; do
    docker network rm "$NETWORK" >/dev/null 2>&1 && break
    sleep 1
  done
}
trap cleanup EXIT
trap 'exit 130' INT TERM

# Starts the server of TARGET (with LIMIT for the service's general rate limit: 0 disables it)
start_server() {
  local target=$1 limit=${2:-0}
  stop_server
  case $target in
    minio)
      docker run -d --label $RUN --name $SERVER --network "$NETWORK" -p 18080:9000 \
        -e MINIO_ROOT_USER=$ACCESS -e MINIO_ROOT_PASSWORD=$SECRET \
        "$MINIO_IMAGE" server /data >/dev/null
      HOST=$SERVER:9000 ;;
    *)
      docker run -d --label $RUN --name $SERVER --network "$NETWORK" -p 18080:8080 \
        -e FEATHER_ACCESS=$ACCESS -e FEATHER_SECRET=$SECRET -e JWT_SECRET=bench-jwt \
        -e KEYS_ENCRYPTION_SECRET=bench-keys -e RATE_LIMIT_REQUESTS="$limit" -e LOG_LEVEL=warning \
        feather-io >/dev/null
      HOST=$SERVER:8080 ;;
  esac
  for _ in $(seq 1 30); do
    curl -s http://localhost:18080/ > /dev/null && return
    sleep 1
  done
  echo "the server didn't start" >&2
  exit 1
}

stop_server() { docker rm -fv $SERVER >/dev/null 2>&1; }

# Runs warp with the arguments after NAME, its summary in NAME.txt and the server's memory in
# NAME.mem while it runs
scenario() {
  local name=$1; shift
  if [ -n "$ONLY" ] && ! [[ $name =~ $ONLY ]]; then return; fi
  echo "--- $name"
  : > "$TARGET_DIR/$name.mem"
  (while true; do
     # The RSS of the server's process in KiB (docker stats would count the page cache of the
     # files it reads)
     docker top $SERVER -o pid,rss 2>/dev/null | awk 'NR > 1 {print $2}' >> "$TARGET_DIR/$name.mem"
     sleep 2
   done) &
  SAMPLER=$!
  docker run --rm --label $RUN --network "$NETWORK" "$WARP_IMAGE" "$@" \
    --host "$HOST" --access-key $ACCESS --secret-key $SECRET --no-color \
    > "$TARGET_DIR/$name.txt" 2>&1
  kill $SAMPLER 2>/dev/null; wait $SAMPLER 2>/dev/null; SAMPLER=
  grep -E "^Report:|Average:" "$TARGET_DIR/$name.txt" | head -4
}

run_target() {
  local target=$1
  TARGET_DIR=$OUT_DIR/$target
  [ -z "$ONLY" ] && rm -rf "$TARGET_DIR"
  mkdir -p "$TARGET_DIR"
  start_server "$target" 0
  docker inspect --format '{{.Config.Image}}' $SERVER > "$TARGET_DIR/image.txt"

  # Throughput by object size, 8 clients
  scenario put-1KiB put --obj.size 1KiB --concurrent 8 --duration "$DURATION"
  scenario put-1MiB put --obj.size 1MiB --concurrent 8 --duration "$DURATION"
  scenario put-16MiB put --obj.size 16MiB --concurrent 8 --duration "$DURATION"
  scenario get-1KiB get --obj.size 1KiB --objects 1000 --concurrent 8 --duration "$DURATION"
  scenario get-1MiB get --obj.size 1MiB --objects 200 --concurrent 8 --duration "$DURATION"
  scenario get-16MiB get --obj.size 16MiB --objects 40 --concurrent 8 --duration "$DURATION"

  # Clients at once, 1 MiB objects
  scenario put-1MiB-c1 put --obj.size 1MiB --concurrent 1 --duration "$DURATION"
  scenario put-1MiB-c32 put --obj.size 1MiB --concurrent 32 --duration "$DURATION"

  # HEAD, a mix like a real workload, and multipart (64 MiB in 8 MiB parts)
  scenario stat stat --obj.size 1KiB --objects 1000 --concurrent 8 --duration "$DURATION"
  scenario mixed mixed --obj.size 1MiB --objects 500 --concurrent 8 --duration "$DURATION"
  scenario multipart multipart-put --parts 8 --part.size 8MiB --part.concurrent 4 \
    --concurrent 2 --duration "$DURATION"

  # Listings by bucket size. Each size in its own bucket, kept, so ListBuckets is then timed
  # with every object stored so far
  [ -z "$ONLY" ] && : > "$TARGET_DIR/listbuckets.txt"
  for size in $LIST_SIZES; do
    scenario "list-$size" list --objects "$size" --obj.size 1KiB --concurrent 8 \
      --bucket "list-$size" --noclear --duration "$DURATION"
    if [ "$target" = feather ] && { [ -z "$ONLY" ] || [[ list-$size =~ $ONLY ]]; }; then
      python "$(host_path "$DIR/list_buckets.py")" http://localhost:18080 $ACCESS $SECRET 3 \
        >> "$TARGET_DIR/listbuckets.txt" && tail -1 "$TARGET_DIR/listbuckets.txt"
    fi
  done

  # The worst case of a listing: a flat bucket (every object at its root, no folders). warp can't
  # measure it (with --noprefix it counts errors even against MinIO), so list_flat.py does,
  # against the service only
  if [ "$target" = feather ] && { [ -z "$ONLY" ] || [[ list-flat =~ $ONLY ]]; }; then
    echo "--- list-flat"
    python "$(host_path "$DIR/list_flat.py")" http://localhost:18080 $ACCESS $SECRET \
      "${LIST_SIZES##* }" > "$TARGET_DIR/listflat.txt" && cat "$TARGET_DIR/listflat.txt"
  fi
  stop_server
}

# A realistic load with the default general limit: how many requests are refused
run_limited() {
  TARGET_DIR=$OUT_DIR/limited
  rm -rf "$TARGET_DIR" && mkdir -p "$TARGET_DIR"
  start_server feather 2000
  scenario mixed mixed --obj.size 64KiB --objects 200 --concurrent 8 --duration 60s
  stop_server
}

targets=("$@")
[ ${#targets[@]} -eq 0 ] && targets=(feather minio)
for target in "${targets[@]}"; do
  echo "===== $target ====="
  case $target in
    feather | minio) run_target "$target" ;;
    limited) run_limited ;;
    *) echo "unknown target: $target (feather, minio or limited)" ;;
  esac
done
