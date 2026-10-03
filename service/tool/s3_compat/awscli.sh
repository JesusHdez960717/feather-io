#!/usr/bin/env bash
# Batería con la AWS CLI v2 contra feather-io. Se ejecuta dentro de la imagen
# amazon/aws-cli (ver run.sh): ENDPOINT, AWS_ACCESS_KEY_ID y
# AWS_SECRET_ACCESS_KEY vienen del entorno.
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

# la imagen no trae cmp ni diff: se compara con md5sum
same_file() { [ "$(md5sum < "$1")" = "$(md5sum < "$2")" ]; }
tree_hash() { (cd "$1" && find . -type f -exec md5sum {} + | sort); }
same_tree() { [ "$(tree_hash "$1")" = "$(tree_hash "$2")" ]; }

echo "version: $(aws --version 2>&1)"

# --- datos ---
mkdir -p "$WORK/up/sub" "$WORK/down"
head -c 1024 /dev/urandom > "$WORK/up/small.txt"
head -c $((20 * 1024 * 1024)) /dev/urandom > "$WORK/up/big.bin"
echo "con espacios" > "$WORK/up/sub/con espacio + signo.txt"
: > "$WORK/up/empty.txt"

# --- buckets ---
step "s3 mb" aws_ s3 mb "s3://$BUCKET"
step "s3 ls (buckets)" sh -c "aws --endpoint-url '$ENDPOINT' s3 ls | grep -q '$BUCKET'"
step "s3api head-bucket" aws_ s3api head-bucket --bucket "$BUCKET"
step "s3api get-bucket-location" aws_ s3api get-bucket-location --bucket "$BUCKET"

# --- subidas (la CLI v2 manda aws-chunked con CRC32 en el trailer) ---
step "s3 cp pequeño" aws_ s3 cp "$WORK/up/small.txt" "s3://$BUCKET/dir/small.txt"
step "s3 cp vacío" aws_ s3 cp "$WORK/up/empty.txt" "s3://$BUCKET/empty.txt"
step "s3 cp multipart (20 MiB)" aws_ s3 cp "$WORK/up/big.bin" "s3://$BUCKET/big.bin"
step "s3 cp key con espacios y +" aws_ s3 cp "$WORK/up/sub/con espacio + signo.txt" "s3://$BUCKET/raros/con espacio + signo.txt"
step "s3api put-object con metadatos" aws_ s3api put-object --bucket "$BUCKET" --key meta.txt \
  --body "$WORK/up/small.txt" --content-type text/csv --metadata autor=feather --storage-class STANDARD_IA

# --- lecturas ---
step "s3 ls --recursive" sh -c "aws --endpoint-url '$ENDPOINT' s3 ls 's3://$BUCKET' --recursive | grep -q 'raros/con espacio + signo.txt'"
step "s3api list-objects (v1)" aws_ s3api list-objects --bucket "$BUCKET" --max-items 2
step "s3api list-objects-v2 paginado" sh -c "aws --endpoint-url '$ENDPOINT' s3api list-objects-v2 --bucket '$BUCKET' --page-size 1 --query 'length(Contents)' | grep -q 5"
step "s3api head-object (metadatos)" sh -c "aws --endpoint-url '$ENDPOINT' s3api head-object --bucket '$BUCKET' --key meta.txt | grep -q '\"autor\": \"feather\"'"
step "s3api head-object (content-type y clase)" sh -c "aws --endpoint-url '$ENDPOINT' s3api head-object --bucket '$BUCKET' --key meta.txt | grep -q STANDARD_IA"
step "s3 cp descarga pequeño" aws_ s3 cp "s3://$BUCKET/dir/small.txt" "$WORK/down/small.txt"
step "  contenido igual" same_file "$WORK/up/small.txt" "$WORK/down/small.txt"
step "s3 cp descarga multipart (rangos)" aws_ s3 cp "s3://$BUCKET/big.bin" "$WORK/down/big.bin"
step "  contenido igual" same_file "$WORK/up/big.bin" "$WORK/down/big.bin"
step "s3 cp descarga key rara" aws_ s3 cp "s3://$BUCKET/raros/con espacio + signo.txt" "$WORK/down/raro.txt"
step "  contenido igual" same_file "$WORK/up/sub/con espacio + signo.txt" "$WORK/down/raro.txt"
step "s3api get-object --range" sh -c "aws --endpoint-url '$ENDPOINT' s3api get-object --bucket '$BUCKET' --key dir/small.txt --range bytes=0-9 '$WORK/down/range.bin' >/dev/null && [ \$(wc -c < '$WORK/down/range.bin') -eq 10 ]"

# --- copias, movimientos, presign ---
step "s3 cp servidor a servidor" aws_ s3 cp "s3://$BUCKET/dir/small.txt" "s3://$BUCKET/copia/small.txt"
step "s3 cp multipart servidor a servidor" aws_ s3 cp "s3://$BUCKET/big.bin" "s3://$BUCKET/copia/big.bin"
step "s3 mv" aws_ s3 mv "s3://$BUCKET/copia/small.txt" "s3://$BUCKET/movido/small.txt"
step "s3 presign + curl" sh -c "curl -sf \"\$(aws --endpoint-url '$ENDPOINT' s3 presign 's3://$BUCKET/dir/small.txt')\" -o '$WORK/down/presign.txt'"
step "  contenido igual" same_file "$WORK/up/small.txt" "$WORK/down/presign.txt"

# --- sync ---
step "s3 sync subida" aws_ s3 sync "$WORK/up" "s3://$BUCKET/sync/"
step "s3 sync sin cambios no sube nada" sh -c "[ -z \"\$(aws --endpoint-url '$ENDPOINT' s3 sync '$WORK/up' 's3://$BUCKET/sync/')\" ]"
step "s3 sync bajada" aws_ s3 sync "s3://$BUCKET/sync/" "$WORK/sync-down/"
step "  contenido igual" same_tree "$WORK/up" "$WORK/sync-down"

# --- borrados ---
step "s3 rm" aws_ s3 rm "s3://$BUCKET/movido/small.txt"
step "s3 rm --recursive (DeleteObjects)" aws_ s3 rm "s3://$BUCKET" --recursive
step "bucket vacío" sh -c "[ -z \"\$(aws --endpoint-url '$ENDPOINT' s3 ls 's3://$BUCKET' --recursive)\" ]"
step "s3 rb" aws_ s3 rb "s3://$BUCKET"

rm -rf "$WORK"
echo
echo "aws-cli: $PASS PASS, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
