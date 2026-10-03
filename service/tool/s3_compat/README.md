# Pruebas de compatibilidad S3

Clientes S3 reales, en Docker, contra un feather-io ya arrancado. No forman parte de
`dart test`: se lanzan a mano antes de una versión o tras tocar la API S3.

| Objetivo | Qué es                                                                                                                                     |
|----------|--------------------------------------------------------------------------------------------------------------------------------------------|
| `awscli` | `awscli.sh` con la imagen `amazon/aws-cli` (CLI v2 actual: firma por trozos `aws-chunked` con CRC32, multipart, rangos, `sync`, presign…). |
| `rclone` | `rclone.sh` con la imagen `rclone/rclone`: `copy`, `sync`, `check` por md5 (ETag), multipart, `cat` con rangos, `purge`…                   |
| `mint`   | [MinIO Mint](https://github.com/minio/mint) (imagen `minio/mint`, de 2024): las suites de los SDKs de AWS y de MinIO, s3cmd y mc.          |

## Uso

Arranca el servicio (ver `service/README.md`) y, desde la raíz del repo:

```bash
ACCESS_KEY=access SECRET_KEY=secret service/tool/s3_compat/run.sh          # awscli y rclone
ACCESS_KEY=access SECRET_KEY=secret service/tool/s3_compat/run.sh mint     # Mint (unos 5 min)
MINT_SUITES="minio-go s3cmd" service/tool/s3_compat/run.sh mint            # solo algunas suites
```

`ACCESS_KEY`/`SECRET_KEY` son `FEATHER_ACCESS`/`FEATHER_SECRET`. `ENDPOINT` (por defecto
`http://host.docker.internal:8080`) es el servicio visto desde los contenedores. Cada paso imprime
`PASS` o `FAIL` (con la salida del error) y el script termina con error si algo falla. La salida de
cada objetivo se guarda en `out/` (`awscli.txt`, `rclone.txt`, `mint.txt` y `mint-logs/log.json`;
otra carpeta con `OUT_DIR`), que no se sube al repo.

Mira también el log del servicio: los clientes reintentan, así que un error 500 puede no verse en
la batería y sí en el servidor (`[ERROR] Unhandled error`).

## Resumen de resultados

`report.py` escribe [`RESULTADOS.md`](RESULTADOS.md) a partir de `out/` (más el JSON de
`dart test` y los análisis estáticos): cada test del servicio, cada paso de los clientes y cada
resultado de Mint con su causa. El procedimiento completo, paso a paso, está en *Full test run* de
`CLAUDE.md`.

```bash
python service/tool/s3_compat/report.py --server-log <log del servicio>
```

## Resultados (octubre de 2026)

El detalle de la última ejecución completa, test a test, está en [`RESULTADOS.md`](RESULTADOS.md).

- `awscli` (aws-cli 2.37.9): 34/34. `rclone` (v1.75.1): 19/19.
- Mint: pasan enteras `aws-sdk-java`, `aws-sdk-java-v2`, `minio-java`, `minio-go` (sin SigV2) y
  `s3cmd`. El resto se corta en funciones fuera de alcance:

| Suite          | Se corta en                                                                                    |
|----------------|------------------------------------------------------------------------------------------------|
| `awscli`       | `s3 presign` de la CLI v1, que firma con SigV2                                                 |
| `aws-sdk-go`   | espera `XAmzContentSHA256Mismatch` (no se valida `x-amz-content-sha256`)                       |
| `aws-sdk-php`  | abortar una subida inexistente: espera 204 como MinIO; S3 y feather-io dan 404                 |
| `aws-sdk-ruby` | subida con POST policy                                                                         |
| `minio-py`     | snowball (API propia de MinIO)                                                                 |
| `minio-js`     | POST policy, notificaciones, S3 Select, retention, force-delete de MinIO y keys con `<>:"\|?*` |
| `mc`           | POST policy                                                                                    |

Fuera de alcance (ver *Aparcado* en `ROADMAP.md`): SigV2, POST policy, validar sha256/checksums,
versionado, etiquetas, notificaciones, S3 Select, retention/object lock, las APIs propias de MinIO
y las keys con caracteres que el sistema de ficheros no admite.
