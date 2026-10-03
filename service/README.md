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

## Configurar clientes S3

Cualquier cliente S3 vale con estas opciones: el endpoint del servicio, **path-style** (el bucket
va en la ruta, no en el host), región `us-east-1` y las claves `FEATHER_ACCESS` /
`FEATHER_SECRET`. Probados: AWS CLI v2, rclone, s3cmd, mc y los SDKs de AWS (Java, PHP, Ruby) y de
MinIO (Go, Java, JS, Python). Las pruebas están en `tool/s3_compat/`.

**AWS CLI**

```ini
# ~/.aws/config
[profile feather]
region = us-east-1
endpoint_url = http://localhost:8080
s3 =
  addressing_style = path
```

```bash
AWS_ACCESS_KEY_ID=access AWS_SECRET_ACCESS_KEY=secret aws --profile feather s3 ls
```

**rclone**

```ini
# rclone.conf
[feather]
type = s3
provider = Other
access_key_id = access
secret_access_key = secret
endpoint = http://localhost:8080
region = us-east-1
force_path_style = true
```

**boto3**

```python
s3 = boto3.client(
    "s3",
    endpoint_url="http://localhost:8080",
    aws_access_key_id="access",
    aws_secret_access_key="secret",
    region_name="us-east-1",
    config=botocore.config.Config(s3={"addressing_style": "path"}),
)
```

No están soportados: SigV2, subidas con POST policy, versionado, etiquetas, políticas de bucket,
notificaciones ni S3 Select (los subrecursos sin implementar responden `501 NotImplemented`).

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
| `MAX_OBJECT_SIZE`       |    No     |  `5368709120`  | Tamaño máximo en bytes de un objeto subido con `PUT` (5 GiB por defecto); por encima responde `EntityTooLarge`. |
| `JWT_SECRET`            |  **SI**   |         -          | Clave secreta para firmar los jwt.                                                                  |
| `LOGIN_MAX_FAILURES`    |    No     |        `10`        | Logins fallidos seguidos que bloquean una IP.                                                       |
| `LOGIN_LOCK_SECONDS`    |    No     |       `900`        | Segundos que dura el bloqueo de una IP (responde `429` con `Retry-After`).                          |
| `LOGIN_FAILURE_DELAY_MS`|    No     |       `1000`       | Espera antes de responder a cada login fallido.                                                     |
| `TRUSTED_PROXIES`       |    No     |        `0`         | Proxies propios delante del servicio; con 0 se usa la IP de la conexión y se ignora `X-Forwarded-For`. |
