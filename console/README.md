## Integracion

Por ahora la consola SIEMPRE utiliza content negotiation a json y jwt para todas las operaciones,
incluyendo las de S# que soportan sigv4

## Env (Console)

| Variable       | Requerido | Por defecto | Descripción                                                                    |
|:---------------|:---------:|:-----------:|:-------------------------------------------------------------------------------|
| `SERVICE_URL`  |  **Sí**   |      -      | URL del servicio backend.                                                      |
| `ADMIN_PREFIX` |    No     |  `_admin`   | Prefijo para la consola de administración (debe coincidir con el del service). |