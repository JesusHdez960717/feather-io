#!/usr/bin/env bash
# AWS CLI v2 battery against feather-io. Runs inside the amazon/aws-cli image
# (see run.sh): ENDPOINT, AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY come from
# the environment.
set -u

BUCKET="cli-compat-$RANDOM"
WORK=$(mktemp -d)
PASS=0
FAIL=0

export AWS_DEFAULT_REGION=us-east-1
mkdir -p ~/.aws
printf '[default]\ns3 =\n  addressing_style = path\n' > ~/.aws/config

aws_() { aws --endpoint-url "$ENDPOINT" "$@"; }

step() {
  local name=$1
  shift
  local out
  if out=$("$@" 2>&1); then
    PASS=$((PASS + 1))
    echo "PASS  $name"
  else
    FAIL=$((FAIL + 1))
    echo "FAIL  $name"
    echo "$out" | sed 's/^/      /' | tail -n 8
  fi
}

# The image has neither cmp nor diff: compare with md5sum
same_file() { [ "$(md5sum < "$1")" = "$(md5sum < "$2")" ]; }
tree_hash() { (cd "$1" && find . -type f -exec md5sum {} + | sort); }
same_tree() { [ "$(tree_hash "$1")" = "$(tree_hash "$2")" ]; }

echo "version: $(aws --version 2>&1)"

# --- data ---
mkdir -p "$WORK/up/sub" "$WORK/down"
head -c 1024 /dev/urandom > "$WORK/up/small.txt"
head -c $((20 * 1024 * 1024)) /dev/urandom > "$WORK/up/big.bin"
echo "with spaces" > "$WORK/up/sub/with space + sign.txt"
: > "$WORK/up/empty.txt"

# --- buckets ---
step "s3 mb" aws_ s3 mb "s3://$BUCKET"
step "s3 ls (buckets)" sh -c "aws --endpoint-url '$ENDPOINT' s3 ls | grep -q '$BUCKET'"
step "s3api head-bucket" aws_ s3api head-bucket --bucket "$BUCKET"
step "s3api get-bucket-location" aws_ s3api get-bucket-location --bucket "$BUCKET"

# --- uploads (CLI v2 sends aws-chunked with a CRC32 trailer) ---
step "s3 cp small" aws_ s3 cp "$WORK/up/small.txt" "s3://$BUCKET/dir/small.txt"
step "s3 cp empty" aws_ s3 cp "$WORK/up/empty.txt" "s3://$BUCKET/empty.txt"
step "s3 cp multipart (20 MiB)" aws_ s3 cp "$WORK/up/big.bin" "s3://$BUCKET/big.bin"
step "s3 cp key with spaces and +" aws_ s3 cp "$WORK/up/sub/with space + sign.txt" "s3://$BUCKET/odd/with space + sign.txt"
step "s3api put-object with metadata" aws_ s3api put-object --bucket "$BUCKET" --key meta.txt \
  --body "$WORK/up/small.txt" --content-type text/csv --metadata author=feather --storage-class STANDARD_IA

# --- reads ---
step "s3 ls --recursive" sh -c "aws --endpoint-url '$ENDPOINT' s3 ls 's3://$BUCKET' --recursive | grep -q 'odd/with space + sign.txt'"
step "s3api list-objects (v1)" aws_ s3api list-objects --bucket "$BUCKET" --max-items 2
step "s3api list-objects-v2 paged" sh -c "aws --endpoint-url '$ENDPOINT' s3api list-objects-v2 --bucket '$BUCKET' --page-size 1 --query 'length(Contents)' | grep -q 5"
step "s3api head-object (metadata)" sh -c "aws --endpoint-url '$ENDPOINT' s3api head-object --bucket '$BUCKET' --key meta.txt | grep -q '\"author\": \"feather\"'"
step "s3api head-object (content-type and class)" sh -c "aws --endpoint-url '$ENDPOINT' s3api head-object --bucket '$BUCKET' --key meta.txt | grep -q STANDARD_IA"
step "s3 cp download small" aws_ s3 cp "s3://$BUCKET/dir/small.txt" "$WORK/down/small.txt"
step "  same content" same_file "$WORK/up/small.txt" "$WORK/down/small.txt"
step "s3 cp download multipart (ranges)" aws_ s3 cp "s3://$BUCKET/big.bin" "$WORK/down/big.bin"
step "  same content" same_file "$WORK/up/big.bin" "$WORK/down/big.bin"
step "s3 cp download odd key" aws_ s3 cp "s3://$BUCKET/odd/with space + sign.txt" "$WORK/down/odd.txt"
step "  same content" same_file "$WORK/up/sub/with space + sign.txt" "$WORK/down/odd.txt"
step "s3api get-object --range" sh -c "aws --endpoint-url '$ENDPOINT' s3api get-object --bucket '$BUCKET' --key dir/small.txt --range bytes=0-9 '$WORK/down/range.bin' >/dev/null && [ \$(wc -c < '$WORK/down/range.bin') -eq 10 ]"

# --- copies, moves, presign ---
step "s3 cp server to server" aws_ s3 cp "s3://$BUCKET/dir/small.txt" "s3://$BUCKET/copy/small.txt"
step "s3 cp multipart server to server" aws_ s3 cp "s3://$BUCKET/big.bin" "s3://$BUCKET/copy/big.bin"
step "s3 mv" aws_ s3 mv "s3://$BUCKET/copy/small.txt" "s3://$BUCKET/moved/small.txt"
step "s3 presign + curl" sh -c "curl -sf \"\$(aws --endpoint-url '$ENDPOINT' s3 presign 's3://$BUCKET/dir/small.txt')\" -o '$WORK/down/presign.txt'"
step "  same content" same_file "$WORK/up/small.txt" "$WORK/down/presign.txt"

# --- sync ---
step "s3 sync upload" aws_ s3 sync "$WORK/up" "s3://$BUCKET/sync/"
step "s3 sync without changes uploads nothing" sh -c "[ -z \"\$(aws --endpoint-url '$ENDPOINT' s3 sync '$WORK/up' 's3://$BUCKET/sync/')\" ]"
step "s3 sync download" aws_ s3 sync "s3://$BUCKET/sync/" "$WORK/sync-down/"
step "  same content" same_tree "$WORK/up" "$WORK/sync-down"

# --- deletes ---
step "s3 rm" aws_ s3 rm "s3://$BUCKET/moved/small.txt"
step "s3 rm --recursive (DeleteObjects)" aws_ s3 rm "s3://$BUCKET" --recursive
step "bucket empty" sh -c "[ -z \"\$(aws --endpoint-url '$ENDPOINT' s3 ls 's3://$BUCKET' --recursive)\" ]"
step "s3 rb" aws_ s3 rb "s3://$BUCKET"

rm -rf "$WORK"
echo
echo "aws-cli: $PASS PASS, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
