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

- [ ] **Filtros en el browser** (consola): por tipo, tamaño, fecha y texto, en cliente sobre la
  lista ya cargada.
- [ ] **Editar bucket**
    - [ ] Servicio: `PUT /{admin}/bucket/{bucket}` para descripción y color.
    - [ ] Consola: form de edición reutilizando `bucket_create_form`.

## Fase 2: Detalle de bucket

- [ ] Servicio: `GET /{admin}/bucket/{bucket}` con metadatos, estadísticas y reglas.
- [ ] Servicio: registrar `AnonymousAccessFilter` en las rutas S3, con tests de acceso anónimo.
- [ ] Consola: pantalla de lista de buckets con su detalle
    - [ ] General: nombre, descripción, color, fechas, tamaño y número de objetos.
    - [ ] Reglas de acceso: CRUD sobre la API existente (feature `anonymous_access` que depende de
      `buckets`).
    - [ ] Zona de peligro: vaciar y borrar el bucket.

## Fase 3: Browser completo

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
