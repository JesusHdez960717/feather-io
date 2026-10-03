#!/bin/sh
# Batería con rclone contra feather-io. Se ejecuta dentro de la imagen
# rclone/rclone (ver run.sh): ENDPOINT, AWS_ACCESS_KEY_ID y
# AWS_SECRET_ACCESS_KEY vienen del entorno.
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
# multipart a partir de 10 MiB, en partes de 5 MiB
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

# --- datos ---
mkdir -p "$WORK/up/sub/deep" "$WORK/down"
head -c 1024 /dev/urandom > "$WORK/up/small.txt"
head -c $((25 * 1024 * 1024)) /dev/urandom > "$WORK/up/big.bin"
echo "hola" > "$WORK/up/sub/con espacio + signo.txt"
echo "dentro" > "$WORK/up/sub/deep/file.txt"
: > "$WORK/up/empty.txt"

step "mkdir (bucket)" rclone mkdir "$REMOTE"
step "lsd (buckets)" sh -c "rclone lsd feather: | grep -q '${REMOTE#feather:}'"
step "copy (incluye multipart 25 MiB)" rclone copy "$WORK/up" "$REMOTE/datos"
step "ls" sh -c "rclone ls '$REMOTE' | grep -q 'datos/sub/con espacio + signo.txt'"
step "lsd (carpetas)" sh -c "rclone lsd '$REMOTE/datos' | grep -q sub"
step "md5sum (ETag)" sh -c "rclone md5sum '$REMOTE/datos/small.txt' | grep -q \$(md5sum < '$WORK/up/small.txt' | cut -c1-32)"
step "check (tamaño y hash)" rclone check "$WORK/up" "$REMOTE/datos"
step "copy de vuelta" rclone copy "$REMOTE/datos" "$WORK/down"
step "  contenido igual" diff -r "$WORK/up" "$WORK/down"
step "cat" sh -c "[ \"\$(rclone cat '$REMOTE/datos/sub/deep/file.txt')\" = dentro ]"
step "cat --offset/--count (Range)" sh -c "[ \"\$(rclone cat --offset 1 --count 3 '$REMOTE/datos/sub/deep/file.txt')\" = ent ]"
step "copyto en el servidor" rclone copyto "$REMOTE/datos/small.txt" "$REMOTE/copias/small.txt"
step "moveto en el servidor" rclone moveto "$REMOTE/copias/small.txt" "$REMOTE/movidos/small.txt"

# sync: cambia uno, borra otro y comprueba que el remoto queda igual
echo "cambiado" > "$WORK/up/small.txt"
rm "$WORK/up/empty.txt"
step "sync con cambios" rclone sync "$WORK/up" "$REMOTE/datos"
step "check tras sync" rclone check "$WORK/up" "$REMOTE/datos"
step "sync sin cambios no transfiere" sh -c "rclone sync '$WORK/up' '$REMOTE/datos' -v 2>&1 | grep -q 'There was nothing to transfer'"

step "delete (DeleteObjects)" rclone delete "$REMOTE/movidos"
step "purge (bucket entero), sin errores" sh -c "! rclone purge '$REMOTE' 2>&1 | grep ERROR"
step "bucket borrado" sh -c "! rclone lsd feather: | grep -q '${REMOTE#feather:}'"

rm -rf "$WORK"
echo
echo "rclone: $PASS PASS, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
