# Resultados de las pruebas (ejecución completa desde cero)

Ejecución del **2026-10-02** sobre el commit `2c17fa6` (`feature/poc`),
en Windows 11 con Docker version 29.4.1, build 055a478.
Generado con `service/tool/s3_compat/report.py`; cómo repetirlo: *Full test run* en `CLAUDE.md`.

| Qué | Resultado |
|---|---|
| `dart analyze` (servicio) | Sin incidencias |
| `flutter analyze` (consola) | 1 aviso (ver la salida) |
| `dart test` (servicio) | **307/307** en 26 ficheros |
| AWS CLI v2 (`aws-cli/2.37.9`) | **34/34** |
| rclone (`rclone v1.75.1`) | **19/19** |
| MinIO Mint (15 suites) | Sin ningún fallo: `aws-sdk-java`, `aws-sdk-java-v2`, `s3cmd`. Terminan con fallos fuera de alcance: `minio-go`, `minio-java`. Fallos sin clasificar: **0** |
| Errores sin capturar en el log del servicio | **0** |

## 1. Tests del servicio (`dart test`)

| Fichero | Tests | Qué cubre |
|---|---:|---|
| `anonymous_access_test.dart` | 25/25 | Reglas de acceso anónimo por prefijo (CRUD admin y efecto en list/get/put/delete) y que multipart nunca es anónimo. |
| `aws_chunked_test.dart` | 10/10 | Cuerpos `aws-chunked` (firma por trozos y trailers), cortes a mitad de línea, errores y que una subida fallida no pisa el objeto. |
| `body_size_test.dart` | 7/7 | Límites de tamaño: objetos > 10 MB, cuerpos de 2 MB, chunked sin `Content-Length`. |
| `copy_object_test.dart` | 17/17 | CopyObject: copia, entre buckets, sobre sí mismo, errores y condiciones `x-amz-copy-source-if-*`. |
| `cors_test.dart` | 3/3 | CORS (preflight y `ETag` expuesto). |
| `create_bucket_test.dart` | 11/11 | CreateBucket: JWT y SigV4, sin cuerpo ni `Content-Length`, metadatos, validación y reservados. |
| `create_folder_test.dart` | 14/14 | Carpetas (`key/`): crear, listar, HEAD/GET y borrado como S3 (solo el marcador). |
| `delete_bucket_test.dart` | 7/7 | DeleteBucket: vacío, no vacío, inexistente, reservado, SigV4. |
| `delete_folder_test.dart` | 7/7 | Endpoint admin para borrar una carpeta con su contenido. |
| `delete_object_test.dart` | 16/16 | DeleteObject y DeleteObjects (JSON y XML de S3), borrados en paralelo y reintento en Windows. |
| `empty_bucket_test.dart` | 5/5 | Endpoint admin para vaciar un bucket. |
| `get_bucket_location_test.dart` | 4/4 | GetBucketLocation (`?location`). |
| `get_bucket_test.dart` | 6/6 | Detalle de bucket (admin): metadatos y estadísticas. |
| `get_object_test.dart` | 26/26 | GET/HEAD: tipos, ETag, `Range` (206/416), overrides `response-*`. |
| `list_buckets_test.dart` | 7/7 | ListBuckets: JSON/XML, fechas UTC, `Owner`, estadísticas. |
| `list_objects_test.dart` | 21/21 | ListObjects V1 y V2: prefijos, paginación (token, `marker`, `start-after`), ETags, `encoding-type=url`. |
| `login_test.dart` | 9/9 | Login de la consola (JWT) y tokens manipulados: sin `exp`, caducados, con otro secreto, `alg: none`; errores sin detalles internos. |
| `multipart_test.dart` | 31/31 | Multipart: crear, partes, completar, abortar, ListMultipartUploads, ListParts, UploadPartCopy. |
| `object_metadata_test.dart` | 12/12 | Metadatos: `Content-Type`, `x-amz-meta-*`, clase de almacenamiento, en copias y multipart. |
| `presign_test.dart` | 11/11 | URLs prefirmadas (endpoint admin y verificación SigV4 por query). |
| `put_object_test.dart` | 13/13 | PutObject: subidas, ETag, bucket inexistente, validación de keys, path traversal y sustituir un objeto abierto (Windows). |
| `s3_controller_test.dart` | 5/5 | Camino feliz completo (crear bucket → subir → listar → bajar → borrar). |
| `s3_error_test.dart` | 17/17 | Errores S3 en XML/JSON y firmas SigV4: firma y clave erróneas, replay (±15 min), fecha de la credencial, sha256 del cuerpo, URL prefirmada con fecha futura. |
| `sig_v4_signer_test.dart` | 3/3 | Firma SigV4 contra el ejemplo oficial de la documentación de AWS. |
| `unsupported_subresource_test.dart` | 9/9 | `501 NotImplemented` para subrecursos y las lecturas que sí se contestan (tagging, versioning). |
| `update_bucket_test.dart` | 11/11 | Editar descripción y color de un bucket (admin). |

La consola no tiene tests (está en el roadmap, fase 5); solo se analiza.

## 2. Clientes reales: AWS CLI v2 y rclone

Scripts `awscli.sh` y `rclone.sh` (qué prueba cada paso: ver los scripts). Cada paso compara
también el contenido cuando baja algo.

| Cliente | Pasos | Fallan |
|---|---:|---|
| AWS CLI v2 (`aws-cli/2.37.9`) | 34/34 | — |
| rclone (`rclone v1.75.1`) | 19/19 | — |

## 3. MinIO Mint

Cada suite prueba con un SDK o herramienta. Muchas se cortan en su primer fallo; NA son tests
que la propia suite salta. `aws-sdk-java`, `aws-sdk-java-v2` y `minio-go` solo apuntan en el
log los fallos y los saltados: que pasan se sabe por su código de salida (*Termina bien*).

| Suite | Termina bien | ✅ | ❌ | NA | Estado |
|---|:---:|---:|---:|---:|---|
| `awscli` | ❌ | 10 | 1 | 0 | Se corta en `s3 presign` (SigV2 de la CLI v1). |
| `aws-sdk-go` | ❌ | 0 | 1 | 0 | Se corta en el primer test: espera que una URL prefirmada valide el `x-amz-content-sha256` de una cabecera. |
| `aws-sdk-java` | ✅ | — | 0 | 0 | Pasa entera. |
| `aws-sdk-java-v2` | ✅ | — | 0 | 0 | Pasa entera. |
| `aws-sdk-php` | ❌ | 11 | 1 | 0 | Se corta al abortar una subida inexistente (comportamiento de MinIO). |
| `aws-sdk-ruby` | ❌ | 12 | 1 | 0 | Se corta en POST policy. |
| `minio-go` | ✅ | — | 1 | 1 | Pasa entera con SigV4; la parte SigV2 da 401. |
| `minio-py` | ❌ | 10 | 1 | 6 | Se corta en snowball (API de MinIO). |
| `minio-js` | ❌ | 195 | 13 | 0 | Llega al final con fallos sueltos (cada bloque sigue tras un fallo). |
| `minio-java` | ✅ | 27 | 11 | 32 | Llega al final con fallos sueltos. |
| `mc` | ❌ | 15 | 1 | 0 | Se corta en POST policy. |
| `s3cmd` | ✅ | 8 | 0 | 0 | Pasa entera. |
| `healthcheck` | ❌ | 0 | 1 | 0 | Fuera de alcance: endpoints de salud de MinIO. |
| `s3select` | ❌ | 0 | 1 | 0 | Fuera de alcance: S3 Select. |
| `versioning` | ❌ | 0 | 1 | 0 | Fuera de alcance: versionado. |

### Fallos y su causa

| Suite | Test | Causa |
|---|---|---|
| `awscli` | aws --endpoint-url http://host.docker.internal:8080 s3 presign s3://awscli-mint-test-buck… | Fuera de alcance: la CLI v1 firma `s3 presign` con SigV2. |
| `aws-sdk-go` | PresignedPut | Fuera de alcance: en una URL prefirmada no se valida el `x-amz-content-sha256` (sí con firma por cabecera). |
| `aws-sdk-php` | abortMultipartupload ( array $params = [] ) | Comportamiento de MinIO: abortar una subida inexistente da 204; AWS S3 (y feather-io) dan 404 `NoSuchUpload`. |
| `aws-sdk-ruby` | presignedPost(bucket_name,file_name,expires_in_sec,max_byte_size) | Fuera de alcance: subidas con POST policy. |
| `minio-go` | MakeBucket(bucketName, location) | Fuera de alcance: firma SigV2. |
| `minio-py` |  | Fuera de alcance: snowball es una API propia de MinIO. |
| `minio-js` | presignedPostPolicy(postPolicy, cb) | Fuera de alcance: subidas con POST policy. |
| `minio-js` | presignedPostPolicy(postPolicy, cb) | Fuera de alcance: subidas con POST policy. |
| `minio-js` | listObjects(bucketName, prefix, recursive) | En cascada: queda `datafile-1-b`, que borraban las pruebas de POST policy (fuera de alcance). |
| `minio-js` | listenBucketNotification(bucketName, prefix, suffix, events) | Fuera de alcance: notificaciones (minio-java además repite el parámetro `events` en la query; ver observaciones). |
| `minio-js` | putObjectRetention(bucketName, objectName, putOpts) | Fuera de alcance: retention / object lock. |
| `minio-js` | putObject(bucketName, objectName, stream) | Limitación: keys con `<>:"\|?*`, que el sistema de ficheros (Windows) no admite. |
| `minio-js` | putObject(bucketName, objectName, stream) | Limitación: keys con `<>:"\|?*`, que el sistema de ficheros (Windows) no admite. |
| `minio-js` | putObject(bucketName, objectName, stream) | Limitación: keys con `<>:"\|?*`, que el sistema de ficheros (Windows) no admite. |
| `minio-js` | selectObjectContent(bucketName, objectName, selectOpts) | Fuera de alcance: S3 Select. |
| `minio-js` | "after all" hook for "Remove Object post select of content: | En cascada: el bucket de S3 Select no se vacía. |
| `minio-js` | listObjects(bucketName, prefix, recursive) | En cascada: force-delete de prefijos, propio de MinIO. |
| `minio-js` | "after all" hook in "Force Deletion of prefix" | En cascada: force-delete de prefijos, propio de MinIO. |
| `minio-js` | "after all" hook in "functional tests" | En cascada: el bucket principal se queda con objetos de pruebas que fallaron antes. |
| `minio-java` | listenBucketNotification() | Fuera de alcance: notificaciones (minio-java además repite el parámetro `events` en la query; ver observaciones). |
| `minio-java` | getPresignedPostFormData() | Fuera de alcance: subidas con POST policy. |
| `minio-java` | uploadSnowballObjects() | Fuera de alcance: snowball es una API propia de MinIO. |
| `minio-java` | uploadSnowballObjects() | Fuera de alcance: snowball es una API propia de MinIO. |
| `minio-java` | removeBucket() | En cascada: el bucket de snowball no se vacía. |
| `minio-java` | addUser() | Fuera de alcance: API de administración de MinIO. |
| `minio-java` | addCannedPolicy() | Fuera de alcance: API de administración de MinIO. |
| `minio-java` | setPolicy() | Fuera de alcance: API de administración de MinIO. |
| `minio-java` | getUserInfo() | Fuera de alcance: API de administración de MinIO. |
| `minio-java` | listUsers() | Fuera de alcance: API de administración de MinIO. |
| `minio-java` | listCannedPolicies() | Fuera de alcance: API de administración de MinIO. |
| `mc` | test_presigned_post_policy_error | Fuera de alcance: subidas con POST policy. |
| `healthcheck` | testLivenessEndpoint | Fuera de alcance: endpoint de salud propio de MinIO. |
| `s3select` | select_object_content(bucket_name, object_name, request) | Fuera de alcance: S3 Select. |
| `versioning` | /mint/build/versioning/bucket.go:66: main.testMakeBucket | Fuera de alcance: versionado. |

## 4. Lo que no funciona

**Fuera de alcance** (en *Aparcado* del `ROADMAP.md`; responden `501 NotImplemented` o 401)

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
  `503 ServiceUnavailable` (los clientes lo reintentan). En Linux no pasa.

## 5. Lo que no se ha probado

- **Linux**: el servicio de estas pruebas corre en Windows. Producción iría en Docker sobre Linux,
  y el `Dockerfile` está pendiente de arreglar (fase 5 del roadmap).
- **HTTPS**: todas las pruebas van por HTTP.
- **Virtual-hosted style** (`bucket.host`): solo path-style.
- **Carga y concurrencia altas**: solo la concurrencia que meten los propios clientes (subidas por
  partes y borrados en paralelo).
- **Consola**: no tiene tests automáticos.
- **Otros clientes**: Cyberduck, s3fs, SDKs de .NET y de Rust, boto3 directamente (sí lo usan
  por debajo la CLI de AWS y s3cmd).
