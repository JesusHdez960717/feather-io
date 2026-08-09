# Feather-io Service

## Arquitectura de API

El servicio expone dos APIs principales:

* **S3 API**: Proporciona compatibilidad con el protocolo S3 para la gestión de buckets y objetos.
* **Admin API**: Rutas reservadas para la administración del sistema (accesibles mediante el prefijo
  configurado en `ADMIN_PREFIX`). Esta API **siempre responde en formato JSON**.

> **Nota**: Los recursos de administración deben utilizar el prefijo `_` (ej. `_admin`, que es el
> valor por
> defecto de `ADMIN_PREFIX`) para evitar conflictos de colisión con los nombres de los buckets en la
> raíz de la API S3.

## Content Negotiation (S3 API)

La API de S3 soporta negociación de contenido basada en la cabecera `Accept`:

* **`Accept: application/json`**: El servicio responderá con un cuerpo JSON.
* **Otros / Por defecto**: El servicio responderá en **XML** para mantener la compatibilidad con el
  estándar de S3.
* **Solo aplica a S3**: esto solo aplica a la api de s3, la api de admin siempre devuelve json

## Endpoints y Permisos

Resumen de las acciones disponibles, su método de autenticación y el permiso requerido.

### S3 API (Path: `/`)

| Acción          | Método | Ruta              | Auth        | Permiso                   |
|:----------------|:-------|:------------------|:------------|:--------------------------|
| `list-buckets`  | GET    | `/`               | JWT / SigV4 | `s3.list-buckets`         |
| `list-objects`  | GET    | `/{bucket}`       | JWT / SigV4 | `s3.list-objects`         |
| `put-object`    | PUT    | `/{bucket}/{key}` | JWT / SigV4 | `s3.put-object`           |
| `get-object`    | GET    | `/{bucket}/{key}` | JWT / SigV4 | `s3.get-object`           |
| `delete-object` | DELETE | `/{bucket}/{key}` | JWT / SigV4 | `s3.delete-object`        |
| `multi-delete`  | POST   | `/{bucket}`       | JWT / SigV4 | `s3.multi-delete-objects` |

### Admin API (Path: `/{ADMIN_PREFIX}`)

| Acción            | Método | Ruta                        | Auth         | Permiso                 |
|:------------------|:-------|:----------------------------|:-------------|:------------------------|
| `login`           | POST   | `/login`                    | ***Public*** | -                       |
| `bucket.download` | POST   | `/bucket/{bucket}/download` | JWT          | `admin.bucket.download` |

*\*El login valida directamente contra las credenciales de entorno `FEATHER_ACCESS`
y `FEATHER_SECRET`.*

## Env

Sección de variables de entorno configurables para el servicio.

| Variable                | Requerido |    Por defecto     | Descripción                                                                                         |
|:------------------------|:---------:|:------------------:|:----------------------------------------------------------------------------------------------------|
| `FEATHER_SECRET`        |  **Sí**   |         -          | Clave secreta para la autenticación de las peticiones.                                              |
| `FEATHER_ACCESS`        |  **Sí**   |         -          | Clave de acceso para la autenticación de las peticiones.                                            |
| `STORAGE_VOLUME_PATH`   |  **Sí**   |         -          | Ruta local en el volumen donde se almacenarán los buckets y objetos.                                |
| `ADMIN_PREFIX`          |    No     |      `_admin`      | Prefijo utilizado para la consola de administración y rutas reservadas del sistema.                 |
| `RESERVED_BUCKET_NAMES` |    No     | ***(empty list)*** | Lista (separada por comas) de nombres de buckets reservados que no pueden ser creados por usuarios. |
| `JWT_SECRET`            |  **SI**   |         -          | Clave secreta para firmar los jwt.                                                                  |
