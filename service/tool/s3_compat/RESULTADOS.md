# Resultados de las pruebas (ejecución completa desde cero)

Ejecución del **2026-10-02** sobre el commit `3a05004` (`feature/poc`),
en Windows 11 con Docker version 29.4.1, build 055a478.
Generado con `service/tool/s3_compat/report.py`; cómo repetirlo: *Full test run* en `CLAUDE.md`.

| Qué | Resultado |
|---|---|
| `dart analyze` (servicio) | Sin incidencias |
| `flutter analyze` (consola) | 1 aviso (ver la salida) |
| `dart test` (servicio) | **288/288** en 26 ficheros |
| AWS CLI v2 (`aws-cli/2.37.9`) | **34/34** |
| rclone (`rclone v1.75.1`) | **19/19** |
| MinIO Mint (15 suites) | Sin ningún fallo: `aws-sdk-java`, `aws-sdk-java-v2`, `s3cmd`. Terminan con fallos fuera de alcance: `minio-go`, `minio-java`. Fallos sin clasificar: **0** |
| Errores sin capturar en el log del servicio | **0** |

## 1. Tests del servicio (`dart test`)

| Fichero | Tests | Qué cubre |
|---|---:|---|
| `anonymous_access_test.dart` | 19/19 | Reglas de acceso anónimo por prefijo (CRUD admin y efecto en list/get/put/delete). |
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
| `login_test.dart` | 4/4 | Login de la consola (JWT). |
| `multipart_test.dart` | 31/31 | Multipart: crear, partes, completar, abortar, ListMultipartUploads, ListParts, UploadPartCopy. |
| `object_metadata_test.dart` | 12/12 | Metadatos: `Content-Type`, `x-amz-meta-*`, clase de almacenamiento, en copias y multipart. |
| `presign_test.dart` | 11/11 | URLs prefirmadas (endpoint admin y verificación SigV4 por query). |
| `put_object_test.dart` | 12/12 | PutObject: subidas, ETag, bucket inexistente, validación de keys, path traversal y sustituir un objeto abierto (Windows). |
| `s3_controller_test.dart` | 5/5 | Camino feliz completo (crear bucket → subir → listar → bajar → borrar). |
| `s3_error_test.dart` | 10/10 | Errores S3 en XML/JSON y validación de firmas SigV4. |
| `sig_v4_signer_test.dart` | 3/3 | Firma SigV4 contra el ejemplo oficial de la documentación de AWS. |
| `unsupported_subresource_test.dart` | 9/9 | `501 NotImplemented` para subrecursos y las lecturas que sí se contestan (tagging, versioning). |
| `update_bucket_test.dart` | 11/11 | Editar descripción y color de un bucket (admin). |

<details><summary>Lista completa de tests</summary>

**anonymous_access_test.dart**

- ✅ Anonymous access - Rules API Should list the rules in creation order
- ✅ Anonymous access - Rules API Should reject an unknown access type (422)
- ✅ Anonymous access - Rules API Should reject an empty prefix (422)
- ✅ Anonymous access - Rules API Should return 404 for rules of a non-existent bucket
- ✅ Anonymous access - Rules API Should delete a rule
- ✅ Anonymous access - Rules API Should fail without auth (401)
- ✅ Anonymous access - S3 requests without credentials readOnly: should download an object under the prefix
- ✅ Anonymous access - S3 requests without credentials readOnly: should list the prefix
- ✅ Anonymous access - S3 requests without credentials readOnly: should not upload or delete (401)
- ✅ Anonymous access - S3 requests without credentials Should deny objects that no rule covers (401)
- ✅ Anonymous access - S3 requests without credentials Should deny listing the whole bucket (401)
- ✅ Anonymous access - S3 requests without credentials writeOnly: should upload and delete but not read
- ✅ Anonymous access - S3 requests without credentials readWrite: should upload, read and delete
- ✅ Anonymous access - S3 requests without credentials Should support * as a wildcard
- ✅ Anonymous access - S3 requests without credentials Should treat regex characters in the prefix literally
- ✅ Anonymous access - S3 requests without credentials Should never allow an anonymous multi-delete (401)
- ✅ Anonymous access - S3 requests without credentials Should not apply the rules of one bucket to another
- ✅ Anonymous access - S3 requests without credentials Should stop working once the rule is deleted
- ✅ Anonymous access - Bucket lifecycle Should drop the rules when the bucket is deleted

**aws_chunked_test.dart**

- ✅ AwsChunkedDecoder - PutObject Should store the content without the chunk signatures
- ✅ AwsChunkedDecoder - PutObject Should ignore the trailing checksums
- ✅ AwsChunkedDecoder - PutObject Should store an empty object
- ✅ AwsChunkedDecoder - PutObject Should decode a body that arrives cut at any byte
- ✅ AwsChunkedDecoder - PutObject Should not store aws-chunked as the Content-Encoding
- ✅ AwsChunkedDecoder - PutObject Should reject a malformed chunk size (400) and store nothing
- ✅ AwsChunkedDecoder - PutObject Should keep the previous object when an upload fails
- ✅ AwsChunkedDecoder - PutObject Should not list the temporary folder as a bucket
- ✅ AwsChunkedDecoder - PutObject Should reject a body without the last chunk (400)
- ✅ AwsChunkedDecoder - UploadPart Should decode the parts of a multipart upload

**body_size_test.dart**

- ✅ BodySizeFilter - objects Should upload an object bigger than 10 MB
- ✅ BodySizeFilter - objects Should reject an object over MAX_OBJECT_SIZE with EntityTooLarge
- ✅ BodySizeFilter - objects Should answer EntityTooLarge as JSON when asked
- ✅ BodySizeFilter - other requests Should reject a JSON body over 2 MB (413)
- ✅ BodySizeFilter - other requests Should accept a chunked body without Content-Length
- ✅ BodySizeFilter - other requests Should cut a chunked body over 2 MB while reading it (413)
- ✅ BodySizeFilter - other requests Should still accept a normal JSON request

**copy_object_test.dart**

- ✅ S3Controller - CopyObject (x-amz-copy-source) Should copy an object and keep the source
- ✅ S3Controller - CopyObject (x-amz-copy-source) Should answer the copied object in JSON when accepted
- ✅ S3Controller - CopyObject (x-amz-copy-source) Should copy between buckets and accept a URL-encoded source
- ✅ S3Controller - CopyObject (x-amz-copy-source) Should overwrite an existing target
- ✅ S3Controller - CopyObject (x-amz-copy-source) Should return 404 for a missing source object
- ✅ S3Controller - CopyObject (x-amz-copy-source) Should return 404 for a missing target bucket
- ✅ S3Controller - CopyObject (x-amz-copy-source) Should return 404 for a missing source bucket
- ✅ S3Controller - CopyObject (x-amz-copy-source) Should reject copying an object onto itself without changes (400)
- ✅ S3Controller - CopyObject (x-amz-copy-source) Should copy an object onto itself to change its metadata
- ✅ S3Controller - CopyObject (x-amz-copy-source) Should copy an object onto itself to change its storage class
- ✅ S3Controller - CopyObject (x-amz-copy-source) Should reject a malformed source (400)
- ✅ S3Controller - CopyObject (x-amz-copy-source) Should reject a path traversal in the source (400)
- ✅ S3Controller - CopyObject (x-amz-copy-source) Should fail without auth (401)
- ✅ S3Controller - CopyObject (x-amz-copy-source) Should not let an anonymous writer copy a private object (403)
- ✅ S3Controller - CopyObject conditions Should copy when the conditions hold
- ✅ S3Controller - CopyObject conditions Should fail with 412 when a condition does not hold
- ✅ S3Controller - CopyObject conditions Should ignore a date it does not understand

**cors_test.dart**

- ✅ CORS Tests Preflight request (OPTIONS) should return CORS headers
- ✅ CORS Tests GET with Origin header should include CORS headers, even on 401
- ✅ CORS Tests GET without Origin header should not include CORS headers

**create_bucket_test.dart**

- ✅ S3Controller - Create Bucket PUT /{bucket} - Should fail without token (401)
- ✅ S3Controller - Create Bucket PUT /{bucket} - Should fail with a wrong token (401)
- ✅ S3Controller - Create Bucket PUT /{bucket} - Should create a bucket signed with SigV4
- ✅ S3Controller - Create Bucket PUT /{bucket} - Should accept a request without Content-Length nor body
- ✅ S3Controller - Create Bucket PUT /{bucket} - Should create a bucket with description and color
- ✅ S3Controller - Create Bucket PUT /{bucket} - Should create a bucket without body
- ✅ S3Controller - Create Bucket PUT /{bucket} - Should reject an existing bucket (409)
- ✅ S3Controller - Create Bucket PUT /{bucket} - Should reject an invalid name (400)
- ✅ S3Controller - Create Bucket PUT /{bucket} - Should reject a reserved name (403)
- ✅ S3Controller - Create Bucket PUT /{bucket} - Should reject a description that is too long (422)
- ✅ S3Controller - Create Bucket PUT /{bucket} - Should reject an out of range color (422)

**create_folder_test.dart**

- ✅ S3Controller - Create folder (PUT key/) Should create an empty folder listed as a common prefix
- ✅ S3Controller - Create folder (PUT key/) Should list the folder itself as a 0 byte key inside it
- ✅ S3Controller - Create folder (PUT key/) Should create nested folders
- ✅ S3Controller - Create folder (PUT key/) Should keep the folder after deleting its last object
- ✅ S3Controller - Create folder (PUT key/) Should not count the folder as an object in the bucket stats
- ✅ S3Controller - Create folder (PUT key/) Should only delete the folder marker, like S3, keeping its content
- ✅ S3Controller - Create folder (PUT key/) Should delete an empty folder
- ✅ S3Controller - Create folder (PUT key/) Should not delete a directory addressed without the slash
- ✅ S3Controller - Create folder (PUT key/) Should only delete the marker in a multi-delete too
- ✅ S3Controller - Create folder (PUT key/) Should reject the folder marker name as a key (400)
- ✅ S3Controller - Create folder (PUT key/) Should fail without auth (401)
- ✅ S3Controller - Create folder (PUT key/) Should answer HEAD and GET on the folder as an empty object
- ✅ S3Controller - Create folder (PUT key/) Should answer 404 on HEAD of a folder that does not exist
- ✅ S3Controller - Create folder (PUT key/) Should delete a bucket that only has empty folders (204)

**delete_bucket_test.dart**

- ✅ S3Controller - Delete Bucket DELETE /{bucket} - Should delete an empty bucket (204)
- ✅ S3Controller - Delete Bucket DELETE /{bucket} - Should delete a bucket signed with SigV4 (204)
- ✅ S3Controller - Delete Bucket DELETE /{bucket} - Should reject a non-empty bucket (409)
- ✅ S3Controller - Delete Bucket DELETE /{bucket} - Should return 404 for a non-existent bucket
- ✅ S3Controller - Delete Bucket DELETE /{bucket} - Should reject a reserved name (403)
- ✅ S3Controller - Delete Bucket DELETE /{bucket} - Should fail without auth (401)
- ✅ S3Controller - Delete Bucket DELETE /{bucket} - Should reject an invalid name (400)

**delete_folder_test.dart**

- ✅ AdminController - Delete folder Should delete the folder with all its content
- ✅ AdminController - Delete folder Should delete a nested folder and clean its empty parents
- ✅ AdminController - Delete folder Should succeed for a folder that does not exist
- ✅ AdminController - Delete folder Should reject a prefix that is not a folder (400)
- ✅ AdminController - Delete folder Should reject a missing prefix and a path traversal (400)
- ✅ AdminController - Delete folder Should return 404 for a missing bucket
- ✅ AdminController - Delete folder Should fail without auth (401)

**delete_object_test.dart**

- ✅ S3Controller - DELETE Object Should delete file successfully
- ✅ S3Controller - DELETE Object Should retry deleting a file that is open for a moment
- ✅ S3Controller - DELETE Object Should delete many objects of a folder in parallel
- ✅ S3Controller - DELETE Object Should clean up empty parent folders after delete
- ✅ S3Controller - DELETE Object Should succeed if file does not exist (204, idempotent)
- ✅ S3Controller - DELETE Object Should fail without auth (401)
- ✅ S3Controller - DELETE Object Should fail with invalid key (400)
- ✅ S3Controller - Multi-delete Objects Should delete several objects
- ✅ S3Controller - Multi-delete Objects Should report invalid keys with their S3 code
- ✅ S3Controller - Multi-delete Objects Should require the ?delete parameter (400)
- ✅ S3Controller - Multi-delete Objects Should reject an invalid JSON body (400)
- ✅ S3Controller - Multi-delete Objects Should reject a body that is neither JSON nor <Delete> (400)
- ✅ S3Controller - Multi-delete Objects (S3 XML) Should delete several objects and answer the S3 XML
- ✅ S3Controller - Multi-delete Objects (S3 XML) Should only list the errors in quiet mode
- ✅ S3Controller - Multi-delete Objects (S3 XML) Should accept a request signed with SigV4
- ✅ S3Controller - Multi-delete Objects (S3 XML) Should reject more than 1000 keys (400)

**empty_bucket_test.dart**

- ✅ AdminController - Empty Bucket Should delete every object and keep the bucket, metadata and rules
- ✅ AdminController - Empty Bucket Should allow deleting the bucket once it is empty
- ✅ AdminController - Empty Bucket Should succeed on an already empty bucket
- ✅ AdminController - Empty Bucket Should return 404 for a non-existent bucket
- ✅ AdminController - Empty Bucket Should fail without auth (401)

**get_bucket_location_test.dart**

- ✅ S3Controller - GetBucketLocation (?location) Should answer an empty LocationConstraint (us-east-1)
- ✅ S3Controller - GetBucketLocation (?location) Should answer a request signed with SigV4
- ✅ S3Controller - GetBucketLocation (?location) Should return 404 for a missing bucket
- ✅ S3Controller - GetBucketLocation (?location) Should fail without auth (401)

**get_bucket_test.dart**

- ✅ AdminController - Get Bucket Should return the metadata and stats of the bucket
- ✅ AdminController - Get Bucket Should return a null last_modified for an empty bucket
- ✅ AdminController - Get Bucket Should return 404 for a non-existent bucket
- ✅ AdminController - Get Bucket Should reject an invalid bucket name (400)
- ✅ AdminController - Get Bucket Should reject a reserved bucket name (403)
- ✅ AdminController - Get Bucket Should fail without auth (401)

**get_object_test.dart**

- ✅ S3Controller - GET Object Should download successfully with auth
- ✅ S3Controller - GET Object Should send the content type of the file
- ✅ S3Controller - GET Object Should fail without auth (401)
- ✅ S3Controller - GET Object Should return 404 for non-existent file
- ✅ S3Controller - GET Object Should return 404 for non-existent bucket
- ✅ S3Controller - GET Object Should return 400 for invalid bucket name
- ✅ S3Controller - GET Object Should return 400 for invalid key
- ✅ S3Controller - HEAD Object Should answer the headers without the body
- ✅ S3Controller - HEAD Object Should send Last-Modified on GET too
- ✅ S3Controller - HEAD Object Should answer an object without extension as octet-stream
- ✅ S3Controller - HEAD Object Should send the ETag (md5 of the content)
- ✅ S3Controller - HEAD Object Should return 404 for a missing object
- ✅ S3Controller - HEAD Object Should fail without auth (401)
- ✅ S3Controller - GET Object (no extension, ETag) Should download an object without extension as octet-stream
- ✅ S3Controller - GET Object (no extension, ETag) Should send the ETag (md5 of the content)
- ✅ S3Controller - GET Object (no extension, ETag) Should recompute the ETag when the file changes outside
- ✅ S3Controller - GET Object (Range) Should answer a closed range with 206
- ✅ S3Controller - GET Object (Range) Should answer an open range up to the end
- ✅ S3Controller - GET Object (Range) Should answer the last bytes with a suffix range
- ✅ S3Controller - GET Object (Range) Should cut a range that goes past the end
- ✅ S3Controller - GET Object (Range) Should answer the whole object for a suffix bigger than it
- ✅ S3Controller - GET Object (Range) Should reject a range that starts after the end (416)
- ✅ S3Controller - GET Object (Range) Should ignore a malformed range and answer everything
- ✅ S3Controller - GET Object (Range) Should send only the headers of the range on HEAD
- ✅ S3Controller - GET Object (response-* overrides) Should override the response headers from the query
- ✅ S3Controller - GET Object (response-* overrides) Should ignore the overrides of an anonymous request

**list_buckets_test.dart**

- ✅ S3Controller - List Buckets GET / - Should fail without auth (401)
- ✅ S3Controller - List Buckets GET / - Should return empty list initially (JSON)
- ✅ S3Controller - List Buckets GET / - Should list buckets after upload (JSON)
- ✅ S3Controller - List Buckets GET / - Should list multiple buckets and update stats (JSON)
- ✅ S3Controller - List Buckets GET / - Should include the metadata of created buckets
- ✅ S3Controller - List Buckets GET / - Should return XML by default
- ✅ S3Controller - List Buckets GET / - Should update stats after deleting a file

**list_objects_test.dart**

- ✅ S3Controller - LIST Objects Should list objects in JSON
- ✅ S3Controller - LIST Objects Should group folders with prefix and delimiter
- ✅ S3Controller - LIST Objects Should list objects in XML by default
- ✅ S3Controller - LIST Objects Should send the ETag and a UTC LastModified in the XML
- ✅ S3Controller - LIST Objects Should send the ETag in JSON
- ✅ S3Controller - LIST Objects Should escape the XML special chars of the keys
- ✅ S3Controller - LIST Objects Should return an empty list for an empty prefix
- ✅ S3Controller - LIST Objects Should fail without auth (401)
- ✅ S3Controller - LIST Objects Should fail with an invalid token (401)
- ✅ S3Controller - LIST Objects Should return 404 if bucket does not exist
- ✅ S3Controller - LIST Objects pagination Should walk every key in order with max-keys and the token
- ✅ S3Controller - LIST Objects pagination Should not be truncated when everything fits
- ✅ S3Controller - LIST Objects pagination Should cap max-keys at 1000
- ✅ S3Controller - LIST Objects pagination Should report the V2 pagination in the XML
- ✅ S3Controller - LIST Objects pagination Should walk every key with the V1 marker and NextMarker
- ✅ S3Controller - LIST Objects pagination Should start after start-after in V2
- ✅ S3Controller - LIST Objects pagination Should reject an invalid max-keys (400)
- ✅ S3Controller - LIST Objects pagination Should reject an invalid continuation-token (400)
- ✅ S3Controller - LIST Objects encoding-type=url Should URL-encode the keys, keeping the slashes
- ✅ S3Controller - LIST Objects encoding-type=url Should URL-encode the common prefixes
- ✅ S3Controller - LIST Objects encoding-type=url Should not encode without encoding-type

**login_test.dart**

- ✅ AdminController - Login Should issue a token with valid credentials
- ✅ AdminController - Login Should reject wrong credentials (403)
- ✅ AdminController - Login Should reject a malformed body (400)
- ✅ AdminController - Login Should authorize requests with the issued token

**multipart_test.dart**

- ✅ S3Controller - multipart upload Should create, upload parts and complete (XML)
- ✅ S3Controller - multipart upload Should create and complete with JSON (console)
- ✅ S3Controller - multipart upload Should use the last upload of a repeated part
- ✅ S3Controller - multipart upload Should allow a single small part
- ✅ S3Controller - multipart upload Should abort and remove the parts
- ✅ S3Controller - multipart upload Should not list the pending uploads as a bucket
- ✅ S3Controller - multipart upload Should expose the ETag header to the browser (CORS)
- ✅ S3Controller - multipart errors Should reject a small part that is not the last one
- ✅ S3Controller - multipart errors Should reject parts out of order
- ✅ S3Controller - multipart errors Should reject a missing part or a wrong ETag
- ✅ S3Controller - multipart errors Should reject a malformed part list
- ✅ S3Controller - multipart errors Should answer NoSuchUpload for unknown or foreign ids
- ✅ S3Controller - multipart errors Should reject an invalid part number
- ✅ S3Controller - multipart errors Should fail on a missing bucket or a folder key
- ✅ S3Controller - multipart errors Should reject POST on an object without ?uploads/?uploadId
- ✅ S3Controller - multipart errors Should fail without auth (401)
- ✅ S3Controller - multipart with SigV4 Should create an upload signed with the service keys
- ✅ BucketService - multipart cleanup Should abort the pending uploads when a bucket is deleted
- ✅ S3Controller - ListMultipartUploads (GET ?uploads) Should list the pending uploads of the bucket in XML
- ✅ S3Controller - ListMultipartUploads (GET ?uploads) Should filter by prefix and answer JSON
- ✅ S3Controller - ListMultipartUploads (GET ?uploads) Should not list the uploads of other buckets nor the finished ones
- ✅ S3Controller - ListMultipartUploads (GET ?uploads) Should return 404 for a missing bucket
- ✅ S3Controller - UploadPartCopy Should copy a whole object as a part
- ✅ S3Controller - UploadPartCopy Should copy ranges and complete the object with them
- ✅ S3Controller - UploadPartCopy Should reject a range outside the source (416)
- ✅ S3Controller - UploadPartCopy Should reject a malformed range (400)
- ✅ S3Controller - UploadPartCopy Should check the copy conditions (412)
- ✅ S3Controller - ListParts (GET ?uploadId) Should list the uploaded parts in order (XML)
- ✅ S3Controller - ListParts (GET ?uploadId) Should page with part-number-marker and max-parts (JSON)
- ✅ S3Controller - ListParts (GET ?uploadId) Should answer NoSuchUpload for an unknown upload
- ✅ S3Controller - ListParts (GET ?uploadId) Should not let an anonymous reader list the parts (403)

**object_metadata_test.dart**

- ✅ S3Controller - Object metadata Should keep the headers and x-amz-meta-* of the upload
- ✅ S3Controller - Object metadata Should not store the other request headers
- ✅ S3Controller - Object metadata Should use the extension when no Content-Type was sent
- ✅ S3Controller - Object metadata Should replace the metadata when the object is overwritten
- ✅ S3Controller - Object metadata Should keep the metadata when the file changes outside
- ✅ S3Controller - Object metadata on copy Should copy the metadata of the source by default
- ✅ S3Controller - Object metadata on copy Should use the request metadata with REPLACE
- ✅ S3Controller - Object metadata on multipart Should apply the metadata of CreateMultipartUpload
- ✅ S3Controller - Storage class Should keep the storage class and send it back
- ✅ S3Controller - Storage class Should not send the STANDARD class, like S3
- ✅ S3Controller - Storage class Should reject an unknown storage class (400)
- ✅ S3Controller - Storage class Should take the class of the copy request, not of the source

**presign_test.dart**

- ✅ AdminController - Presign Should return a URL to the same service that expires later
- ✅ AdminController - Presign Should return 404 for a missing object
- ✅ AdminController - Presign Should reject an expiration out of range (422)
- ✅ AdminController - Presign Should fail without auth (401)
- ✅ S3SigV4Filter - presigned URLs Should download the object without credentials
- ✅ S3SigV4Filter - presigned URLs Should reject a tampered signature (403)
- ✅ S3SigV4Filter - presigned URLs Should reject the signature on another object (403)
- ✅ S3SigV4Filter - presigned URLs Should reject a longer expiration than the signed one (403)
- ✅ S3SigV4Filter - presigned URLs Should not allow another method with the same URL (403)
- ✅ S3SigV4Filter - presigned URLs Should reject an expired URL (403)
- ✅ S3SigV4Filter - Authorization header Should accept a request signed with the service keys

**put_object_test.dart**

- ✅ S3Controller - PUT Object Should upload successfully in root
- ✅ S3Controller - PUT Object Should upload successfully in deep folders
- ✅ S3Controller - PUT Object Should answer the ETag (md5 of the content) without body
- ✅ S3Controller - PUT Object Should not create the bucket if it does not exist (404)
- ✅ S3Controller - PUT Object Should fail without auth (401)
- ✅ S3Controller - PUT Object Should fail with an invalid token (401)
- ✅ S3Controller - PUT Object Should fail with invalid bucket name (400)
- ✅ S3Controller - PUT Object Should fail with path traversal in key (400)
- ✅ S3Controller - PUT Object Should fail with invalid characters in key (400)
- ✅ S3Controller - PUT Object over an open file (Windows) Should replace an object that is open for a moment
- ✅ S3Controller - PUT Object over an open file (Windows) Should copy onto an object that is open for a moment
- ✅ S3Controller - PUT Object over an open file (Windows) Should answer 503 and keep the object if it stays open

**s3_controller_test.dart**

- ✅ S3Controller - Happy Path Flow 0. PUT /{bucket} - Should create the bucket
- ✅ S3Controller - Happy Path Flow 1. PUT - Should upload successfully
- ✅ S3Controller - Happy Path Flow 2. GET /{bucket} - Should find the uploaded file
- ✅ S3Controller - Happy Path Flow 3. GET /{key} - Should download the file content
- ✅ S3Controller - Happy Path Flow 4. DELETE - Should remove the file

**s3_error_test.dart**

- ✅ S3Exception - Content negotiation Should answer the S3 <Error> in XML by default
- ✅ S3Exception - Content negotiation Should escape the XML special chars of the message
- ✅ S3Exception - Content negotiation Should answer JSON when the client accepts it
- ✅ S3Exception - Content negotiation Should use the S3 format for errors thrown in filters
- ✅ S3Exception - Content negotiation Should deny a reserved bucket with AccessDenied (403)
- ✅ S3Exception - Admin API Should always answer JSON, even without Accept
- ✅ S3Exception - Admin API Should answer JSON for errors of the download
- ✅ S3SigV4Filter Should reject a SigV4 request with a wrong access key (403)
- ✅ S3SigV4Filter Should reject a SigV4 request with a wrong signature (403)
- ✅ S3SigV4Filter Should accept the Authorization fields without spaces (s3cmd)

**sig_v4_signer_test.dart**

- ✅ SigV4Signer Should encode like AWS: everything but A-Za-z0-9-_.~
- ✅ SigV4Signer Should sort the canonical query by the encoded names
- ✅ SigV4Signer Should match the presigned URL example of the AWS docs

**unsupported_subresource_test.dart**

- ✅ UnsupportedSubresourceFilter Should answer 501 to bucket subresources
- ✅ UnsupportedSubresourceFilter Should not create a bucket with PUT ?versioning
- ✅ UnsupportedSubresourceFilter Should not overwrite an object with PUT ?legal-hold
- ✅ UnsupportedSubresourceFilter Should still serve the supported operations
- ✅ S3Controller - GetObjectTagging Should answer an empty TagSet for an existing object
- ✅ S3Controller - GetObjectTagging Should return 404 for a missing object
- ✅ S3Controller - GetObjectTagging Should still answer 501 to writing tags
- ✅ S3Controller - GetBucketVersioning Should answer that versioning was never enabled
- ✅ S3Controller - GetBucketVersioning Should return 404 for a missing bucket

**update_bucket_test.dart**

- ✅ AdminController - Update Bucket Should update description and color and return the bucket
- ✅ AdminController - Update Bucket Should keep the creation date
- ✅ AdminController - Update Bucket Should clear the fields sent as null
- ✅ AdminController - Update Bucket Should update a bucket created by an upload (without metadata)
- ✅ AdminController - Update Bucket Should return 404 for a non-existent bucket
- ✅ AdminController - Update Bucket Should reject an invalid bucket name (400)
- ✅ AdminController - Update Bucket Should reject a reserved bucket name (403)
- ✅ AdminController - Update Bucket Should reject a description that is too long (422)
- ✅ AdminController - Update Bucket Should reject an out of range color (422)
- ✅ AdminController - Update Bucket Should reject a body that is not JSON (400)
- ✅ AdminController - Update Bucket Should fail without auth (401)

</details>

La consola no tiene tests (está en el roadmap, fase 5); solo se analiza.

## 2. Clientes reales: AWS CLI v2 y rclone

Scripts `awscli.sh` y `rclone.sh`. Cada paso compara también el contenido cuando baja algo.

### AWS CLI v2 (`aws-cli/2.37.9`): 34/34

- ✅ s3 mb
- ✅ s3 ls (buckets)
- ✅ s3api head-bucket
- ✅ s3api get-bucket-location
- ✅ s3 cp pequeño
- ✅ s3 cp vacío
- ✅ s3 cp multipart (20 MiB)
- ✅ s3 cp key con espacios y +
- ✅ s3api put-object con metadatos
- ✅ s3 ls --recursive
- ✅ s3api list-objects (v1)
- ✅ s3api list-objects-v2 paginado
- ✅ s3api head-object (metadatos)
- ✅ s3api head-object (content-type y clase)
- ✅ s3 cp descarga pequeño
- ✅ contenido igual
- ✅ s3 cp descarga multipart (rangos)
- ✅ contenido igual
- ✅ s3 cp descarga key rara
- ✅ contenido igual
- ✅ s3api get-object --range
- ✅ s3 cp servidor a servidor
- ✅ s3 cp multipart servidor a servidor
- ✅ s3 mv
- ✅ s3 presign + curl
- ✅ contenido igual
- ✅ s3 sync subida
- ✅ s3 sync sin cambios no sube nada
- ✅ s3 sync bajada
- ✅ contenido igual
- ✅ s3 rm
- ✅ s3 rm --recursive (DeleteObjects)
- ✅ bucket vacío
- ✅ s3 rb

### rclone (`rclone v1.75.1`): 19/19

- ✅ mkdir (bucket)
- ✅ lsd (buckets)
- ✅ copy (incluye multipart 25 MiB)
- ✅ ls
- ✅ lsd (carpetas)
- ✅ md5sum (ETag)
- ✅ check (tamaño y hash)
- ✅ copy de vuelta
- ✅ contenido igual
- ✅ cat
- ✅ cat --offset/--count (Range)
- ✅ copyto en el servidor
- ✅ moveto en el servidor
- ✅ sync con cambios
- ✅ check tras sync
- ✅ sync sin cambios no transfiere
- ✅ delete (DeleteObjects)
- ✅ purge (bucket entero), sin errores
- ✅ bucket borrado

## 3. MinIO Mint

Cada suite prueba con un SDK o herramienta. Muchas se cortan en su primer fallo; NA son tests
que la propia suite salta. `aws-sdk-java`, `aws-sdk-java-v2` y `minio-go` solo apuntan en el
log los fallos y los saltados: que pasan se sabe por su código de salida (*Termina bien*).

| Suite | Termina bien | ✅ | ❌ | NA | Estado |
|---|:---:|---:|---:|---:|---|
| `awscli` | ❌ | 10 | 1 | 0 | Se corta en `s3 presign` (SigV2 de la CLI v1). |
| `aws-sdk-go` | ❌ | 0 | 1 | 0 | Se corta en el primer test: espera que se valide `x-amz-content-sha256`. |
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
| `aws-sdk-go` | PresignedPut | Fuera de alcance: no se valida `x-amz-content-sha256`. |
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

<details><summary>Tests de Mint que pasan</summary>

**awscli** (10)

- make_bucket
- aws --endpoint-url http://host.docker.internal:8080 s3api get-object --bucket awscli-mint-test-bucket-936 --k…
- aws --endpoint-url http://host.docker.internal:8080 s3api head-object --bucket awscli-mint-test-bucket-26426 …
- aws --endpoint-url http://host.docker.internal:8080 s3api list-objects --bucket awscli-mint-test-bucket-16185…
- aws --endpoint-url http://host.docker.internal:8080 s3api get-object --bucket awscli-mint-test-bucket-11917 -…
- aws --endpoint-url http://host.docker.internal:8080 s3api create-multipart-upload --bucket awscli-mint-test-b…
- aws --endpoint-url http://host.docker.internal:8080 s3api list-objects-v2 --bucket awscli-mint-test-bucket-95…
- aws --endpoint-url http://host.docker.internal:8080 s3api copy-object --bucket awscli-mint-test-bucket-22273 …
- aws --endpoint-url http://host.docker.internal:8080 s3api head-object --bucket awscli-mint-test-bucket-11167 …
- aws --endpoint-url http://host.docker.internal:8080 s3api head-object --bucket awscli-mint-test-bucket-10103 …

**aws-sdk-php** (11)

- getBucketLocation ( array $params = [] )
- listBuckets ( array $params = [] )
- listObjects ( array $params = [] )
- listMultipartUploads ( array $params = [] )
- headBucket ( array $params = [] )
- headObject ( array $params = [] )
- getObject ( array $params = [] )
- copyObject ( array $params = [] )
- deleteObjects (array $params = [] )
- createMultipartUpload ( array $params = [] )
- uploadPart ( array $params = [] )

**aws-sdk-ruby** (12)

- listBuckets()
- listObjects(bucket_name)
- makeBucket(bucket_name)
- bucketExists?(bucket_name)
- removeBucket(bucket_name)
- putObject(bucket_name,file)
- removeObject(bucket_name,file)
- getObject(bucket_name,file,destination)
- copyObject(source_bucket_name,target_bucket_name,source_file_name,target_file_name)
- presignedGet(bucket_name,file_name)
- presignedPut(bucket_name,file_name)

**minio-py** (10)

- make_bucket(bucket_name, location, object_lock)
- remove_bucket(bucket_name)
- 

**minio-js** (195)

- listBuckets(cb)
- listBuckets()
- makeBucket(bucketName, region, cb)
- removeBucket(bucketName, cb)
- makeBucket(bucketName, region)
- removeBucket(bucketName)
- bucketExists(bucketName, cb)
- bucketExists(bucketName)
- putObject(bucketName, objectName, stream)
- getObject(bucketName, objectName, callback)
- removeObject(bucketName, objectName)
- fPutObject(bucketName, objectName, filePath, metaData, callback)
- statObject(bucketName, objectName, cb)
- putObject(bucketName, objectName, stream, size, metaData, callback)
- putObject(bucketName, objectName, stream, callback)
- putObject(bucketName, objectName, stream, metaData)
- getPartialObject(bucketName, objectName, offset, length, cb)
- getObject(bucketName, objectName)
- putObject(bucketName, objectName, stream, metadata, cb)
- getObject(bucketName, objectName, cb)
- copyObject(bucketName, objectName, srcObject, cb)
- copyObject(bucketName, objectName, srcObject)
- statObject(bucketName, objectName)
- putObject(bucketName, objectName, stream, metaData, cb)
- copyObject(bucketName, objectName, srcObject, conditions, cb)
- removeObject(bucketName, objectName, cb)
- initiateNewMultipartUpload(bucketName, objectName, metaData, cb)
- fPutObject(bucketName, objectName, filePath, callback)
- fGetObject(bucketName, objectName, filePath, callback)
- removeObject(bucketName, objectName, filePath, callback)
- fPutObject(bucketName, objectName, filePath, metaData)
- fGetObject(bucketName, objectName, filePath)
- removeObject(bucketName, objectName, callback)
- setBucketPolicy(bucketName, bucketPolicy, cb)
- getBucketPolicy(bucketName, cb)
- presignedPutObject(bucketName, objectName, expires, cb)
- presignedPutObject(bucketName, objectName, expires)
- presignedPutObject(bucketName, objectName)
- presignedGetObject(bucketName, objectName, expires, cb)
- presignedUrl(httpMethod, bucketName, objectName, expires, cb)
- presignedGetObject(bucketName, objectName, cb)
- presignedGetObject(bucketName, objectName, expires)
- presignedGetObject(bucketName, objectName, expires, respHeaders, cb)
- presignedGetObject(bucketName, objectName, respHeaders, cb)
- listObjects(bucketName, prefix, recursive)
- putObject(bucketName, objectName, stream, size, contentType, callback)
- removeObjects with non latin characters
- Check if versioning is enabled on a bucket
- Enable versioning  on a bucket
- Suspend versioning  on a bucket
- Check if versioning is Suspended on a bucket
- setBucketVersioning(bucketName, versionConfig):
- statObject(bucketName, objectName, statOpts)
- removeObject(bucketName, objectName, removeOpts)
- Enable Versioning on Bucket: setBucketVersioning(bucketName,versioningConfig)
- getObject(bucketName, objectName, getOpts)
- fGetObject(bucketName, objectName, filePath, getOpts={})
- getPartialObject(bucketName, objectName, offset, length, getOpts)
- removeObjects(bucketName, objectList, removeOpts)
- Set tags on a bucket
- Get tags on a bucket
- remove Tags on a bucket
- setObjectTagging  object
- getObjectTagging  object
- removeObjectTagging on an object
- removeObject object
- Set tags on an object
- Get tags on an object
- remove Tags on an object
- Set lifecycle config on a bucket:
- Set lifecycle config of a bucket
- Remove lifecycle config of a bucket
- presignedPutObject(bucketName, objectName, expires=1000, cb)
- listObjects(bucketName, '', true, {IncludeVersion: true}, cb)
- presignedGetObject(bucketName, objectName, 1000, respHeaders, requestDate, cb)
- removeObjects(bucketName, objectsList)
- Check if bucket with object lock can be created:
- Get lock config on a bucket:
- Check if bucket can be deleted:
- Update or replace lock config on a bucket:
- Set lock config on a bucket:
- Get and verify lock config on a bucket after reset/update:
- Set Encryption on a bucket:
- Get encryption of a bucket:
- Put an object to check for default encryption bucket:
- Stat of an object to check for default encryption applied on a bucket:
- Remove object on a bucket:
- Remove encryption on a bucket:
- Get encryption on a bucket:
- setObjectLegalHold(bucketName, objectName, setOpts={})
- getObjectLegalHold(bucketName, objectName, setOpts={})
- removeBucket(bucketName, )
- removeObject(bucketName, objectName, stream)
- Create a local file of 100 MB and split
- Upload parts to Bucket
- composeObject(destObjConfig, sourceObjList, cb)::
- statObject(bucketName, objectName, cb)::
- Remove Object Parts from Bucket::
- Remove Composed target Object::
- Clean up temp directory part files
- listIncompleteUploads(bucketName, prefix, recursive)
- removeIncompleteUploads(bucketName, prefix)
- removeObject(bucketName, objectList, removeOpts)

**minio-java** (27)

- makeBucket()
- bucketExists()
- removeBucket()
- listBuckets()
- listObjects()
- putObject()
- getObject()
- removeObject()
- removeObjects()
- statObject()
- copyObject()
- composeObject()
- uploadObject()
- downloadObject()
- getPresignedObjectUrl()

**mc** (15)

- test_make_bucket
- test_make_bucket_error
- test_rb
- test_list_dir
- test_put_object
- test_put_object_error
- test_put_object_0byte
- test_put_object_with_storage_class
- test_put_object_with_storage_class_error
- test_put_object_with_metadata
- test_put_object_multipart
- test_get_object
- test_get_object_multipart
- test_od_object
- test_mv_object

**s3cmd** (8)

- test_make_bucket
- test_make_bucket_error
- test_put_object
- test_put_object_error
- test_put_object_multipart
- test_get_object
- test_get_object_multipart
- test_sync_list_objects

</details>

## 4. Lo que no funciona

**Fuera de alcance** (en *Aparcado* del `ROADMAP.md`; responden `501 NotImplemented` o 401)

- Firma SigV2 (incluido `aws s3 presign` de la CLI v1).
- Validar `x-amz-content-sha256` y los checksums (`Content-MD5`, CRC de `aws-chunked`).
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
