#!/usr/bin/env python3
"""Escribe RESULTADOS.md a partir de las salidas de una ejecucion completa.

Uso (desde la raiz del repo, ver "Pruebas completas" en CLAUDE.md):

    python service/tool/s3_compat/report.py [--out DIR] [--server-log FICHERO]

Lee de --out (por defecto service/tool/s3_compat/out):
    service_tests.jsonl   fvm dart test --reporter json (desde service/)
    service_analyze.txt   fvm dart analyze (opcional)
    console_analyze.txt   fvm flutter analyze (opcional)
    awscli.txt, rclone.txt, mint.txt, mint-logs/log.json   run.sh awscli rclone mint

--server-log es el log del servicio durante la ejecucion, para contar los
errores sin capturar (opcional).

Lo que se mantiene a mano esta en las constantes de arriba: que cubre cada
fichero de tests (TEST_DESC), por que falla cada test de Mint (REASONS) y el
estado de cada suite (SUITE_STATUS). Un fallo de Mint sin causa conocida sale
como **Sin clasificar** y hay que revisarlo.
"""
import argparse
import collections
import datetime
import json
import platform
import re
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent

TEST_DESC = {
    'anonymous_access_test.dart': 'Reglas de acceso anónimo por prefijo (CRUD admin y efecto en list/get/put/delete) y que multipart nunca es anónimo.',
    'aws_chunked_test.dart': 'Cuerpos `aws-chunked` (firma por trozos y trailers), cortes a mitad de línea, errores y que una subida fallida no pisa el objeto.',
    'body_size_test.dart': 'Límites de tamaño: objetos > 10 MB, cuerpos de 2 MB, chunked sin `Content-Length`.',
    'copy_object_test.dart': 'CopyObject: copia, entre buckets, sobre sí mismo, errores y condiciones `x-amz-copy-source-if-*`.',
    'cors_test.dart': 'CORS (preflight y `ETag` expuesto).',
    'create_bucket_test.dart': 'CreateBucket: JWT y SigV4, sin cuerpo ni `Content-Length`, metadatos, validación y reservados.',
    'create_folder_test.dart': 'Carpetas (`key/`): crear, listar, HEAD/GET y borrado como S3 (solo el marcador).',
    'delete_bucket_test.dart': 'DeleteBucket: vacío, no vacío, inexistente, reservado, SigV4.',
    'delete_folder_test.dart': 'Endpoint admin para borrar una carpeta con su contenido.',
    'delete_object_test.dart': 'DeleteObject y DeleteObjects (JSON y XML de S3), borrados en paralelo y reintento en Windows.',
    'empty_bucket_test.dart': 'Endpoint admin para vaciar un bucket.',
    'get_bucket_location_test.dart': 'GetBucketLocation (`?location`).',
    'get_bucket_test.dart': 'Detalle de bucket (admin): metadatos y estadísticas.',
    'get_object_test.dart': 'GET/HEAD: tipos, ETag, `Range` (206/416), overrides `response-*`.',
    'list_buckets_test.dart': 'ListBuckets: JSON/XML, fechas UTC, `Owner`, estadísticas.',
    'list_objects_test.dart': 'ListObjects V1 y V2: prefijos, paginación (token, `marker`, `start-after`), ETags, `encoding-type=url`.',
    'login_test.dart': 'Login de la consola (JWT) y tokens manipulados: sin `exp`, caducados, con otro secreto, `alg: none`; errores sin detalles internos.',
    'multipart_test.dart': 'Multipart: crear, partes, completar, abortar, ListMultipartUploads, ListParts, UploadPartCopy.',
    'object_metadata_test.dart': 'Metadatos: `Content-Type`, `x-amz-meta-*`, clase de almacenamiento, en copias y multipart.',
    'presign_test.dart': 'URLs prefirmadas (endpoint admin y verificación SigV4 por query).',
    'put_object_test.dart': 'PutObject: subidas, ETag, bucket inexistente, validación de keys, path traversal y sustituir un objeto abierto (Windows).',
    's3_controller_test.dart': 'Camino feliz completo (crear bucket → subir → listar → bajar → borrar).',
    's3_error_test.dart': 'Errores S3 en XML/JSON y firmas SigV4: firma y clave erróneas, replay (±15 min), fecha de la credencial, sha256 del cuerpo, URL prefirmada con fecha futura.',
    'sig_v4_signer_test.dart': 'Firma SigV4 contra el ejemplo oficial de la documentación de AWS.',
    'unsupported_subresource_test.dart': '`501 NotImplemented` para subrecursos y las lecturas que sí se contestan (tagging, versioning).',
    'update_bucket_test.dart': 'Editar descripción y color de un bucket (admin).',
}

SUITE_ORDER = ['awscli', 'aws-sdk-go', 'aws-sdk-java', 'aws-sdk-java-v2', 'aws-sdk-php',
               'aws-sdk-ruby', 'minio-go', 'minio-py', 'minio-js', 'minio-java', 'mc', 's3cmd',
               'healthcheck', 's3select', 'versioning']

SUITE_STATUS = {
    'awscli': 'Se corta en `s3 presign` (SigV2 de la CLI v1).',
    'aws-sdk-go': 'Se corta en el primer test: espera que una URL prefirmada valide el `x-amz-content-sha256` de una cabecera.',
    'aws-sdk-java': 'Pasa entera.',
    'aws-sdk-java-v2': 'Pasa entera.',
    'aws-sdk-php': 'Se corta al abortar una subida inexistente (comportamiento de MinIO).',
    'aws-sdk-ruby': 'Se corta en POST policy.',
    'minio-go': 'Pasa entera con SigV4; la parte SigV2 da 401.',
    'minio-py': 'Se corta en snowball (API de MinIO).',
    'minio-js': 'Llega al final con fallos sueltos (cada bloque sigue tras un fallo).',
    'minio-java': 'Llega al final con fallos sueltos.',
    'mc': 'Se corta en POST policy.',
    's3cmd': 'Pasa entera.',
    'healthcheck': 'Fuera de alcance: endpoints de salud de MinIO.',
    's3select': 'Fuera de alcance: S3 Select.',
    'versioning': 'Fuera de alcance: versionado.',
}

# (texto que aparece en el test o su error, causa). Gana el primero que encaja
REASONS = [
    ('s3 presign', 'Fuera de alcance: la CLI v1 firma `s3 presign` con SigV2.'),
    ('XAmzContentSHA256Mismatch', 'Fuera de alcance: en una URL prefirmada no se valida el `x-amz-content-sha256` (sí con firma por cabecera).'),
    ('PresignedPut', 'Fuera de alcance: en una URL prefirmada no se valida el `x-amz-content-sha256` (sí con firma por cabecera).'),
    ('non-existent', 'Comportamiento de MinIO: abortar una subida inexistente da 204; AWS S3 (y feather-io) dan 404 `NoSuchUpload`.'),
    ('presignedPost', 'Fuera de alcance: subidas con POST policy.'),
    ('PresignedPost', 'Fuera de alcance: subidas con POST policy.'),
    ('post_policy', 'Fuera de alcance: subidas con POST policy.'),
    ('testFunctionalV2', 'Fuera de alcance: firma SigV2.'),
    ('snowball', 'Fuera de alcance: snowball es una API propia de MinIO.'),
    ('Snowball', 'Fuera de alcance: snowball es una API propia de MinIO.'),
    ('lists 11 objects', 'En cascada: queda `datafile-1-b`, que borraban las pruebas de POST policy (fuera de alcance).'),
    ('lists 1 objects', 'En cascada: force-delete de prefijos, propio de MinIO.'),
    ('Force Deletion', 'En cascada: force-delete de prefijos, propio de MinIO.'),
    ('listenBucketNotification', 'Fuera de alcance: notificaciones (minio-java además repite el parámetro `events` en la query; ver observaciones).'),
    ('Retention', 'Fuera de alcance: retention / object lock.'),
    ('retention', 'Fuera de alcance: retention / object lock.'),
    ('no es válido o contiene caracteres prohibidos', 'Limitación: keys con `<>:"|?*`, que el sistema de ficheros (Windows) no admite.'),
    ('selectObjectContent', 'Fuera de alcance: S3 Select.'),
    ('select_object_content', 'Fuera de alcance: S3 Select.'),
    ('post select', 'En cascada: el bucket de S3 Select no se vacía.'),
    ('"after all" hook in "functional tests"', 'En cascada: el bucket principal se queda con objetos de pruebas que fallaron antes.'),
    ('removeBucket', 'En cascada: el bucket de snowball no se vacía.'),
    ('addUser', 'Fuera de alcance: API de administración de MinIO.'),
    ('addCannedPolicy', 'Fuera de alcance: API de administración de MinIO.'),
    ('setPolicy', 'Fuera de alcance: API de administración de MinIO.'),
    ('getUserInfo', 'Fuera de alcance: API de administración de MinIO.'),
    ('listUsers', 'Fuera de alcance: API de administración de MinIO.'),
    ('listCannedPolicies', 'Fuera de alcance: API de administración de MinIO.'),
    ('minio/health', 'Fuera de alcance: endpoint de salud propio de MinIO.'),
    ('versioning', 'Fuera de alcance: versionado.'),
]

UNCLASSIFIED = '**Sin clasificar: revisar**'

NOT_WORKING = """**Fuera de alcance** (en *Aparcado* del `ROADMAP.md`; responden `501 NotImplemented` o 401)

- Firma SigV2 (incluido `aws s3 presign` de la CLI v1).
- Validar los checksums (`Content-MD5`, CRC de `aws-chunked`, firmas de cada trozo) y el
  `x-amz-content-sha256` en URLs prefirmadas (con firma por cabecera sí se valida).
- Subidas con POST policy (formularios prefirmados).
- Versionado (solo se contesta que nunca está activado) y etiquetas (solo se contesta que no hay).
- Bucket policies, ACL, cifrado, lifecycle, CORS por bucket, website, logging, replicación.
- Notificaciones, S3 Select, retention / object lock / legal hold.
- APIs propias de MinIO: admin, health, snowball, force-delete de prefijos.
- Keys con caracteres que el sistema de ficheros no admite (`<>:"|?*` en Windows).

**Observaciones**

- La query canónica de SigV4 guarda un solo valor por parámetro: una petición firmada que repite
  un parámetro (`events=…&events=…`, solo lo hace `listenBucketNotification` de MinIO) da
  `SignatureDoesNotMatch`.
- El test de php que aborta una subida inexistente espera el comportamiento de MinIO; el de
  feather-io es el de AWS S3.
- En Windows, sustituir un objeto que otra petición tiene abierto se reintenta 5 s y luego da
  `503 ServiceUnavailable` (los clientes lo reintentan). En Linux no pasa."""

NOT_TESTED = """- **Linux**: el servicio de estas pruebas corre en Windows. Producción iría en Docker sobre Linux,
  y el `Dockerfile` está pendiente de arreglar (fase 5 del roadmap).
- **HTTPS**: todas las pruebas van por HTTP.
- **Virtual-hosted style** (`bucket.host`): solo path-style.
- **Carga y concurrencia altas**: solo la concurrencia que meten los propios clientes (subidas por
  partes y borrados en paralelo).
- **Consola**: no tiene tests automáticos.
- **Otros clientes**: Cyberduck, s3fs, SDKs de .NET y de Rust, boto3 directamente (sí lo usan
  por debajo la CLI de AWS y s3cmd)."""


def md(text):
    return str(text).replace('|', '\\|').replace('\n', ' ').strip()


def short(text, size):
    text = md(text)
    return text if len(text) <= size else text[:size - 1] + '…'


def run(cmd):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=60).stdout.strip()
    except Exception:
        return ''


def read(path):
    return path.read_text(encoding='utf-8', errors='replace') if path.exists() else ''


def load_service_tests(path):
    suites, tests = {}, {}
    for line in read(path).splitlines():
        try:
            event = json.loads(line)
        except ValueError:
            continue
        kind = event.get('type')
        if kind == 'suite':
            suites[event['suite']['id']] = event['suite']['path']
        elif kind == 'testStart':
            test = event['test']
            tests[test['id']] = {'name': test['name'], 'suite': test['suiteID']}
        elif kind == 'testDone' and event['testID'] in tests:
            tests[event['testID']].update(
                result='skipped' if event['skipped'] else event['result'],
                hidden=event['hidden'],
            )
    by_file = collections.defaultdict(list)
    for test in tests.values():
        if test.get('hidden') or 'result' not in test:
            continue
        name = re.split(r'[\\/]', suites.get(test['suite'], '?'))[-1]
        by_file[name].append(test)
    return dict(sorted(by_file.items()))


def load_steps(text):
    return re.findall(r'^(PASS|FAIL)  (.+)$', text, re.M)


def load_mint(out):
    rows = []
    for line in read(out / 'mint-logs' / 'log.json').splitlines():
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        rows.append({
            'suite': str(entry.get('name', '')).split(':')[0].strip(),
            'function': str(entry.get('function') or '').strip(),
            'status': entry.get('status'),
            'text': ' '.join(str(entry.get(k) or '') for k in ('name', 'function', 'error', 'message')),
        })
    done = {m.group(1): m.group(2) == 'done'
            for m in re.finditer(r'Running (\S+) tests \.\.\. (done|FAILED)', read(out / 'mint.txt'))}
    return rows, done


def reason(row):
    for pattern, why in REASONS:
        if pattern in row['text']:
            return why
    return UNCLASSIFIED


def analyze_summary(text, empty):
    if not text:
        return 'No ejecutado'
    if 'No issues found' in text:
        return 'Sin incidencias'
    found = re.search(r'(\d+) issues? found', text)
    if not found:
        return empty
    issues = int(found.group(1))
    return f'{issues} aviso{"s" if issues != 1 else ""} (ver la salida)'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', default=str(HERE / 'out'))
    parser.add_argument('--server-log')
    parser.add_argument('--output', default=str(HERE / 'RESULTADOS.md'))
    args = parser.parse_args()
    out = Path(args.out)

    tests = load_service_tests(out / 'service_tests.jsonl')
    steps = {name: load_steps(read(out / f'{name}.txt')) for name in ('awscli', 'rclone')}
    #solo el primer trozo: `aws-cli/2.37.9`, `rclone v1.75.1`
    versions = {}
    for name in ('awscli', 'rclone'):
        found = re.search(r'^version: (.+)$', read(out / f'{name}.txt'), re.M)
        text = found.group(1) if found else '?'
        versions[name] = ' '.join(text.split()[:2]) if name == 'rclone' else text.split()[0]
    mint, mint_done = load_mint(out)
    by_suite = collections.OrderedDict((s, []) for s in SUITE_ORDER)
    for row in mint:
        by_suite.setdefault(row['suite'], []).append(row)
    counts = {s: collections.Counter(r['status'] for r in rows) for s, rows in by_suite.items()}
    failures = [r for rows in by_suite.values() for r in rows if r['status'] not in ('PASS', 'NA')]
    unclassified = [r for r in failures if reason(r) == UNCLASSIFIED]
    server_errors = None
    if args.server_log:
        server_errors = read(Path(args.server_log)).count('Unhandled error')

    commit = run(['git', 'rev-parse', '--short', 'HEAD']) or '?'
    branch = run(['git', 'rev-parse', '--abbrev-ref', 'HEAD']) or '?'
    #el propio informe y esta carpeta no cuentan como cambios del codigo probado
    dirty = ' con cambios sin commitear' if run(
        ['git', 'status', '--porcelain', '--', 'service', 'console', ':!service/tool/s3_compat']) else ''
    total = sum(len(v) for v in tests.values())
    passed = sum(1 for v in tests.values() for t in v if t['result'] == 'success')

    L = []
    w = L.append
    w('# Resultados de las pruebas (ejecución completa desde cero)')
    w('')
    w(f'Ejecución del **{datetime.date.today().isoformat()}** sobre el commit `{commit}` (`{branch}`){dirty},')
    w(f'en {platform.system()} {platform.release()} con {run(["docker", "--version"]) or "Docker ?"}.')
    w('Generado con `service/tool/s3_compat/report.py`; cómo repetirlo: *Full test run* en `CLAUDE.md`.')
    w('')
    w('| Qué | Resultado |')
    w('|---|---|')
    w(f'| `dart analyze` (servicio) | {analyze_summary(read(out / "service_analyze.txt"), "Ver la salida")} |')
    w(f'| `flutter analyze` (consola) | {analyze_summary(read(out / "console_analyze.txt"), "Ver la salida")} |')
    w(f'| `dart test` (servicio) | **{passed}/{total}** en {len(tests)} ficheros |')
    for name, label in (('awscli', 'AWS CLI v2'), ('rclone', 'rclone')):
        ok = sum(1 for s, _ in steps[name] if s == 'PASS')
        w(f'| {label} (`{versions[name]}`) | **{ok}/{len(steps[name])}** |')
    clean = [s for s in SUITE_ORDER if mint_done.get(s) and counts[s]['FAIL'] == 0]
    partial = [s for s in SUITE_ORDER if mint_done.get(s) and counts[s]['FAIL'] > 0]
    w(f'| MinIO Mint ({len([s for s in SUITE_ORDER if s in mint_done])} suites) | '
      f'Sin ningún fallo: {", ".join(f"`{s}`" for s in clean) or "ninguna"}. '
      f'Terminan con fallos fuera de alcance: {", ".join(f"`{s}`" for s in partial) or "ninguna"}. '
      f'Fallos sin clasificar: **{len(unclassified)}** |')
    if server_errors is not None:
        w(f'| Errores sin capturar en el log del servicio | **{server_errors}** |')
    w('')

    w('## 1. Tests del servicio (`dart test`)')
    w('')
    w('| Fichero | Tests | Qué cubre |')
    w('|---|---:|---|')
    for name, items in tests.items():
        ok = sum(1 for t in items if t['result'] == 'success')
        w(f'| `{name}` | {ok}/{len(items)} | {TEST_DESC.get(name, "**Sin descripción: añadirla en report.py**")} |')
    w('')
    failed_tests = [(name, t) for name, items in tests.items() for t in items
                    if t['result'] != 'success']
    if failed_tests:
        w('Tests que no pasan:')
        w('')
        for name, t in failed_tests:
            w(f'- `{name}`: {md(t["name"])} ({t["result"]})')
        w('')
    w('La consola no tiene tests (está en el roadmap, fase 5); solo se analiza.')
    w('')

    w('## 2. Clientes reales: AWS CLI v2 y rclone')
    w('')
    w('Scripts `awscli.sh` y `rclone.sh` (qué prueba cada paso: ver los scripts). Cada paso compara')
    w('también el contenido cuando baja algo.')
    w('')
    w('| Cliente | Pasos | Fallan |')
    w('|---|---:|---|')
    for name, label in (('awscli', 'AWS CLI v2'), ('rclone', 'rclone')):
        ok = sum(1 for s, _ in steps[name] if s == 'PASS')
        failed = [md(step) for status, step in steps[name] if status != 'PASS']
        w(f'| {label} (`{versions[name]}`) | {ok}/{len(steps[name])} | {"; ".join(failed) or "—"} |')
    w('')

    w('## 3. MinIO Mint')
    w('')
    w('Cada suite prueba con un SDK o herramienta. Muchas se cortan en su primer fallo; NA son tests')
    w('que la propia suite salta. `aws-sdk-java`, `aws-sdk-java-v2` y `minio-go` solo apuntan en el')
    w('log los fallos y los saltados: que pasan se sabe por su código de salida (*Termina bien*).')
    w('')
    w('| Suite | Termina bien | ✅ | ❌ | NA | Estado |')
    w('|---|:---:|---:|---:|---:|---|')
    for s in SUITE_ORDER:
        if s not in mint_done:
            continue
        c = counts[s]
        ok = c['PASS'] if c['PASS'] or not mint_done.get(s) else '—'
        w(f'| `{s}` | {"✅" if mint_done.get(s) else "❌"} | {ok} | {c["FAIL"]} | {c["NA"]} | {SUITE_STATUS.get(s, "")} |')
    w('')
    w('### Fallos y su causa')
    w('')
    w('| Suite | Test | Causa |')
    w('|---|---|---|')
    for row in failures:
        w(f'| `{row["suite"]}` | {short(row["function"], 90)} | {md(reason(row))} |')
    w('')


    w('## 4. Lo que no funciona')
    w('')
    if unclassified or server_errors:
        w('**Pendiente de revisar en esta ejecución**')
        w('')
        for row in unclassified:
            w(f'- Mint `{row["suite"]}`: {short(row["function"], 90)}')
        if server_errors:
            w(f'- {server_errors} errores sin capturar en el log del servicio.')
        w('')
    w(NOT_WORKING)
    w('')
    w('## 5. Lo que no se ha probado')
    w('')
    w(NOT_TESTED)

    Path(args.output).write_text('\n'.join(L) + '\n', encoding='utf-8', newline='\n')
    print(f'Escrito {args.output}')
    print(f'dart test {passed}/{total}; Mint: {len(failures)} fallos, {len(unclassified)} sin clasificar'
          + (f'; {server_errors} errores en el log' if server_errors is not None else ''))
    for row in unclassified:
        print(f'  SIN CLASIFICAR {row["suite"]}: {row["function"][:80]}')


if __name__ == '__main__':
    main()
