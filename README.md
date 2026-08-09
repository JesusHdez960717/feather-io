# Feather-io

S3-Compatible Storage System.

## Arquitectura de API

El servicio backend expone dos interfaces:

*   **S3 API**: Compatible con el protocolo S3.
*   **Admin API**: Gestión interna del sistema (vía `ADMIN_PREFIX`).

> **Importante**: Las rutas administrativas comienzan con `_` (ej. `_admin`) para no entrar en conflicto con los nombres de los buckets de S3.

## Env (Service)

Sección de variables de entorno configurables para el backend (`/service`).

| Variable | Requerido | Por defecto | Descripción |
| :--- | :---: | :---: | :--- |
| `FEATHER_SECRET` | **Sí** | - | Clave secreta para la autenticación de las peticiones. |
| `FEATHER_ACCESS` | **Sí** | - | Clave de acceso para la autenticación de las peticiones. |
| `STORAGE_VOLUME_PATH` | **Sí** | - | Ruta local en el volumen donde se almacenarán los buckets y objetos. |
| `ADMIN_PREFIX` | No | `_admin` | Prefijo utilizado para la consola de administración y rutas reservadas del sistema. |
| `RESERVED_BUCKET_NAMES` | No | `[]` | Lista (separada por comas) de nombres de buckets reservados que no pueden ser creados por usuarios. |

## Env (Console)

| Variable | Requerido | Por defecto | Descripción |
| :--- | :---: | :---: | :--- |
| `SERVICE_URL` | **Sí** | - | URL del servicio backend. |
| `ADMIN_PREFIX` | No | `_admin` | Prefijo para la consola de administración (debe coincidir con el del service). |
