# Roadmap

Orden propuesto de lo que falta en `service/` y `console/`. Marca cada tarea con `[x]` al
terminarla.

## Estado actual

| Área           | Servicio                                                                                                                                           | Consola                                     |
|----------------|----------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------|
| Buckets        | Listar, crear, borrar (descripción y color en SQLite)                                                                                              | Listar, crear, borrar                       |
| Objetos        | Listar (prefix/delimiter), subir, bajar, borrar uno o varios, descarga en zip                                                                      | Todo lo anterior, con preview y drag & drop |
| Acceso anónimo | CRUD de reglas por prefijo (`readOnly`, `writeOnly`, `readWrite`). `AnonymousAccessFilter` no está registrado, así que las reglas no tienen efecto | Nada                                        |
| Auth           | JWT + SigV4, un único usuario por env                                                                                                              | Login                                       |

## Fase 0: Base

- [x] Migrar `service/test/*` a JWT (`JWT_SECRET`, `STORAGE_VOLUME_PATH`).
- [x] `S3Exception` mapeada a códigos de error AWS (`NoSuchBucket`, `BucketNotEmpty`,
  `EntityTooLarge`…), respetando la negociación de contenido.
- [x] Aplicar `ReservedBucketFilter` al crear y borrar buckets (antes se podía crear un bucket
  con un nombre de `RESERVED_BUCKET_NAMES`).

## Fase 1: Resultados rápidos en la consola

- [x] **Filtros en el browser** (consola): por tipo, tamaño, fecha y texto, en cliente sobre la
  lista ya cargada.
- [x] **Editar bucket**
    - [x] Servicio: `PUT /{admin}/bucket/{bucket}` para descripción y color.
    - [x] Consola: form de edición reutilizando `bucket_create_form`.

## Fase 2: Detalle de bucket

- [x] Servicio: `GET /{admin}/bucket/{bucket}` con metadatos y estadísticas (`last_modified`
  incluido). Las reglas se piden aparte, con su endpoint.
- [x] Servicio: `DELETE /{admin}/bucket/{bucket}/objects` para vaciar el bucket; al borrar un
  bucket se borran también sus reglas.
- [x] Servicio: registrar `AnonymousAccessFilter` en las rutas S3, con tests de acceso anónimo.
- [x] Consola: sección *Buckets* con la lista y el detalle (feature `bucket_admin`)
    - [x] General: nombre, descripción, color, fechas, tamaño y número de objetos.
    - [x] Reglas de acceso: crear y borrar (feature `anonymous_access`).
    - [x] Zona de peligro: vaciar y borrar el bucket.
- [x] Consola: entrada *Configuración* desde el explorador (menú del bucket y cabecera), por
  ruta con `RouteNames.openBucketSettings`.
- [x] Consola: mantener sincronizadas la sección *Buckets* y el explorador (cada una tiene sus
  propios cubits; se avisan con `BucketChangedEvent` al crear, editar, vaciar o borrar un bucket y
  al subir o borrar objetos).

## Fase 3: Browser completo

- [x] La URL del explorador guarda el bucket, la carpeta y la vista
  (`/browser?bucket=&folder=&view_type=`), con aviso si el bucket o la carpeta no existen.
- [x] Crear carpeta
    - [x] Servicio: `PUT /{bucket}/{carpeta}/` crea una carpeta vacía (directorio con el marcador
      `.feather-folder`), listada como la key `carpeta/`.
    - [x] Consola: botón *Nueva carpeta* con diálogo.
- [x] Renombrar o mover objetos
    - [x] Servicio: `CopyObject` (`x-amz-copy-source`).
    - [x] Consola: renombrar y mover (uno o varios) con copiar y borrar.
- [x] Detalle de objeto
    - [x] Servicio: `HEAD` object (lo resuelve la ruta `GET`) con `Last-Modified`.
    - [x] Consola: cajón de detalles con miniatura, key, tipo, tamaño, fecha y URL.
- [x] Paginación en list-objects
    - [x] Servicio: `max-keys` (máx. 1000) y `continuation-token`, con `IsTruncated`,
      `NextContinuationToken` y `KeyCount`.
    - [x] Consola: paginador (25, 50, 75 o 100 por página; *Página X de N* con `total_keys`).
      La búsqueda y los filtros miran las páginas ya cargadas.

## Fase 4: Compatibilidad S3

- [x] URLs prefirmadas, con un botón "compartir enlace" en la consola (el servicio firma en
  `POST /{admin}/bucket/{bucket}/presign`; caducidad de 1 hora, 1 día o 7 días).
- [x] Subidas y descargas en segundo plano (consola): ya no bloquean la pantalla con el loading.
  Van a una cola de transferencias de la app (`TransferCubit`, feature `transfers`) que sigue
  aunque se cambie de carpeta, de bucket o de sección, con un indicador siempre visible en el rail
  (sobre el idioma) y un panel con el progreso de cada fichero o zip, cancelar y reintentar. Las
  subidas avisan con `BucketChangedEvent` para que el explorador se recargue solo.
- [x] Multipart upload: crear, subir partes, completar y abortar (sin ListParts ni
  ListMultipartUploads). La consola sube por partes de 8 MiB los ficheros de más de 16 MiB.
- [x] Pruebas contra clientes reales: AWS CLI v2 y rclone pasan enteros, y en Mint los SDKs de
  AWS y MinIO, s3cmd y mc llegan hasta lo que queda fuera de alcance (ver *Aparcado*). Las
  baterías están en `service/tool/s3_compat/`. Arreglos que salieron: SigV4 (permisos de buckets,
  cabecera sin espacios, codificación de la query), `aws-chunked`, `Range`, ETags y metadatos
  reales, DeleteObjects en XML, ListObjects V1 y `encoding-type=url`, GetBucketLocation,
  ListMultipartUploads, ListParts, UploadPartCopy, condiciones de copia, clase de almacenamiento,
  `501` para los subrecursos sin implementar y borrados de carpetas como en S3.

## Fase 5: Operación y producción

- [ ] Gestión de access keys con permisos, con su pantalla de administración en la consola.
- [ ] Ruta de SQLite basada en `STORAGE_VOLUME_PATH`.
- [ ] i18n de los mensajes de error del servicio.
- [ ] Dockerfile: versión de Dart `^3.13` y `libsqlite3` en la imagen final.
- [ ] Tests de la consola (cubits y repos).

## Después de la 1.0 (mejoras futuras)

No entran en la 1.0; se harán más adelante.

- [ ] Renombrar y mover carpetas (hay que copiar y borrar todo su contenido y decidir qué pasa si
  falla a medias).
- [ ] Pasar la búsqueda y los filtros de objetos al servicio, para buscar en toda la carpeta y no
  solo en las páginas ya cargadas.

## Aparcado

- Tema claro de la consola.
- Bucket policies, validación MD5/checksum y casos avanzados de multipart.
- Compatibilidad S3 que no entra (sale en Mint): firma SigV2 (incluido `s3 presign` de la CLI v1),
  validar `x-amz-content-sha256` y los checksums de `aws-chunked`, subidas con POST policy,
  versionado y etiquetas (solo se contesta que no hay), notificaciones, S3 Select,
  retention/object lock y las APIs propias de MinIO (admin, snowball, force-delete).
- Keys con caracteres que el sistema de ficheros no admite (`<>:"|?*` en Windows): habría que
  codificar las keys en disco.

## Ideas

- [ ] Hacer como un Object Mapper para XML y asi no tener los parseToXML en el servicio, que el
  objeto implemente el .toJson o .toXML y cada objeto lo implemente a su manera
- [ ] Reducir el tamaño de la clase s3 controller que tiene más de 1000 líneas de código.
- [ ] Pruebas de rendimiento/benchmark, tal vez con minio wrap?
- [ ] Un Readme decente, con ducumentacion basica pero clara, cosas soportadas, proximos agregos,
  como correrlo...
- [ ] Generar identidad visual/icono como el de brag y video promocional con capturas de pantallas
  reales del diseño