#!/bin/sh
# rclone battery against feather-io. Runs inside the rclone/rclone image (see
# run.sh): ENDPOINT, AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY come from the
# environment.
set -u

REMOTE="feather:rclone-compat-$$"
WORK=$(mktemp -d)
PASS=0
FAIL=0

export RCLONE_CONFIG_FEATHER_TYPE=s3
export RCLONE_CONFIG_FEATHER_PROVIDER=Other
export RCLONE_CONFIG_FEATHER_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
export RCLONE_CONFIG_FEATHER_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
export RCLONE_CONFIG_FEATHER_ENDPOINT="$ENDPOINT"
export RCLONE_CONFIG_FEATHER_REGION=us-east-1
export RCLONE_CONFIG_FEATHER_FORCE_PATH_STYLE=true
# Multipart from 10 MiB on, in 5 MiB parts
export RCLONE_S3_UPLOAD_CUTOFF=10M
export RCLONE_S3_CHUNK_SIZE=5M

step() {
  name=$1
  shift
  if out=$("$@" 2>&1); then
    PASS=$((PASS + 1))
    echo "PASS  $name"
  else
    FAIL=$((FAIL + 1))
    echo "FAIL  $name"
    echo "$out" | sed 's/^/      /' | tail -n 8
  fi
}

echo "version: $(rclone version | head -n 1)"

# --- data ---
mkdir -p "$WORK/up/sub/deep" "$WORK/down"
head -c 1024 /dev/urandom > "$WORK/up/small.txt"
head -c $((25 * 1024 * 1024)) /dev/urandom > "$WORK/up/big.bin"
echo "hello" > "$WORK/up/sub/with space + sign.txt"
echo "inside" > "$WORK/up/sub/deep/file.txt"
: > "$WORK/up/empty.txt"

step "mkdir (bucket)" rclone mkdir "$REMOTE"
step "lsd (buckets)" sh -c "rclone lsd feather: | grep -q '${REMOTE#feather:}'"
step "copy (includes a 25 MiB multipart)" rclone copy "$WORK/up" "$REMOTE/data"
step "ls" sh -c "rclone ls '$REMOTE' | grep -q 'data/sub/with space + sign.txt'"
step "lsd (folders)" sh -c "rclone lsd '$REMOTE/data' | grep -q sub"
step "md5sum (ETag)" sh -c "rclone md5sum '$REMOTE/data/small.txt' | grep -q \$(md5sum < '$WORK/up/small.txt' | cut -c1-32)"
step "check (size and hash)" rclone check "$WORK/up" "$REMOTE/data"
step "copy back" rclone copy "$REMOTE/data" "$WORK/down"
step "  same content" diff -r "$WORK/up" "$WORK/down"
step "cat" sh -c "[ \"\$(rclone cat '$REMOTE/data/sub/deep/file.txt')\" = inside ]"
step "cat --offset/--count (Range)" sh -c "[ \"\$(rclone cat --offset 1 --count 3 '$REMOTE/data/sub/deep/file.txt')\" = nsi ]"
step "copyto on the server" rclone copyto "$REMOTE/data/small.txt" "$REMOTE/copies/small.txt"
step "moveto on the server" rclone moveto "$REMOTE/copies/small.txt" "$REMOTE/moved/small.txt"

# sync: changes one file, deletes another and checks the remote matches
echo "changed" > "$WORK/up/small.txt"
rm "$WORK/up/empty.txt"
step "sync with changes" rclone sync "$WORK/up" "$REMOTE/data"
step "check after sync" rclone check "$WORK/up" "$REMOTE/data"
step "sync without changes transfers nothing" sh -c "rclone sync '$WORK/up' '$REMOTE/data' -v 2>&1 | grep -q 'There was nothing to transfer'"

step "delete (DeleteObjects)" rclone delete "$REMOTE/moved"
step "purge (whole bucket), without errors" sh -c "! rclone purge '$REMOTE' 2>&1 | grep ERROR"
step "bucket deleted" sh -c "! rclone lsd feather: | grep -q '${REMOTE#feather:}'"

rm -rf "$WORK"
echo
echo "rclone: $PASS PASS, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
