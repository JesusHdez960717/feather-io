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
- [ ] Crear carpeta (prefijo vacío).
- [ ] Renombrar o mover objetos
    - [ ] Servicio: `CopyObject` (`x-amz-copy-source`).
    - [ ] Consola: acciones de renombrar y mover.
- [ ] Detalle de objeto
    - [ ] Servicio: `HEAD` object.
    - [ ] Consola: panel de metadatos.
- [ ] Paginación en list-objects (`max-keys`, `continuation-token`) y pasar los filtros al servicio.

## Fase 4: Compatibilidad S3

- [ ] Multipart upload.
- [ ] URLs prefirmadas, con un botón "compartir enlace" en la consola.
- [ ] Pruebas contra clientes reales (aws cli, rclone, SDKs).

## Fase 5: Operación y producción

- [ ] Gestión de access keys con permisos, con su pantalla de administración en la consola.
- [ ] Ruta de SQLite basada en `STORAGE_VOLUME_PATH`.
- [ ] Dockerfile: versión de Dart `^3.13` y `libsqlite3` en la imagen final.
- [ ] i18n de los mensajes de error del servicio.
- [ ] Tests de la consola (cubits y repos).

## Aparcado

- Tema claro de la consola.
- Bucket policies, validación MD5/checksum y casos avanzados de multipart.
