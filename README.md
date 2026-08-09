# Feather-io

S3-Compatible Storage System.

## Arquitectura de API

El servicio backend expone dos interfaces:

* **S3 API**: Compatible con el protocolo S3.
* **Admin API**: Gestión interna del sistema (vía `ADMIN_PREFIX`).

> **Importante**: Las rutas administrativas comienzan con `_` (ej. `_admin`) para no entrar en
> conflicto con los nombres de los buckets de S3.
 
