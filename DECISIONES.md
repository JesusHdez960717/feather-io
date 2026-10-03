# Decisiones de diseño

Por qué el servicio se comporta como se comporta en los puntos que no son obvios leyendo el
código, con los datos que se usaron para decidir. Cuando una decisión cambie, se actualiza aquí.

## 1. Límite de intentos de login

**Qué hace.** `LoginRateLimiter` (en `admin/auth/logic/service/`) cuenta los logins **fallidos** por
IP:

- Cada fallo se responde con **1 segundo de retraso** (`LOGIN_FAILURE_DELAY_MS`).
- Tras **10 fallos seguidos** (`LOGIN_MAX_FAILURES`) la IP queda **bloqueada 15 minutos**
  (`LOGIN_LOCK_SECONDS`): `429 Too Many Requests` con `Retry-After`, **aunque luego acierte**.
- Un login correcto borra los fallos, y los fallos de hace más de 15 minutos dejan de contar.
- Las credenciales se comparan en tiempo constante.

**Por qué.** Hay un único usuario (`FEATHER_ACCESS`/`FEATHER_SECRET`) y el login no tenía ningún
freno: en la revisión de seguridad, 50 contraseñas erróneas seguidas se respondieron todas al
instante, sin bloqueo.

- *El retraso de 1 s* cuesta nada a una persona que se equivoca y limita la fuerza bruta a ~1
  intento por segundo y conexión.
- *El bloqueo* corta los ataques en paralelo, que el retraso solo no frena.
- *Bloquea aunque acierte* porque, si no, el atacante solo tendría que esperar al final del bloqueo
  y seguir probando: el bloqueo no le costaría nada.
- *Cuenta solo fallos* (no todas las peticiones): un usuario legítimo que entra muchas veces no debe
  bloquearse nunca. Por eso no se usa el limitador general de Winter, que cuenta todas.
- *Comparación en tiempo constante*: con `!=` el tiempo de respuesta depende de cuántos caracteres
  coinciden y da pistas sobre el secreto.

**La IP.** Es `request.clientIp(trustedProxies: TRUSTED_PROXIES)` de Winter. Por defecto
(`TRUSTED_PROXIES=0`) se usa la IP de la conexión y se **ignora `X-Forwarded-For`**, porque cualquier
cliente puede mandarla con una IP falsa para saltarse el límite (hay un test que lo comprueba). Detrás
de proxies propios (nginx, un balanceador) hay que poner cuántos son; si no, todos los clientes
comparten la IP del proxy y el bloqueo de uno bloquea a todos.

**Limitaciones conocidas.**

- Vive en memoria: con varias instancias del servicio cada una lleva su cuenta, y reiniciar borra
  los bloqueos.
- Un atacante que conozca la IP de alguien no puede bloquearla salvo que comparta IP con ella (NAT,
  el mismo proxy sin `TRUSTED_PROXIES`).
- Un token ya emitido sigue valiendo durante el bloqueo (dura 12 h).

## 2. Límite general de peticiones

**Qué hace.** `RateLimitFilter` (`security/filter/`), registrado como **primer filtro global** en
`main.dart`, con el `RateLimiter` de Winter (ventana deslizante): como mucho
**`RATE_LIMIT_REQUESTS` peticiones (2000) por IP en cada ventana de `RATE_LIMIT_WINDOW_SECONDS`
(60 s)**. Por encima, la **API S3 responde `503 SlowDown`** con el `<Error>` de S3 (XML, o JSON con
`Accept`), como S3, y la **API de admin `429`**; las dos con `Retry-After`. Todas las respuestas
llevan `X-RateLimit-Limit`, `X-RateLimit-Remaining` y `X-RateLimit-Reset`. Con
`RATE_LIMIT_REQUESTS=0` se desactiva. La IP se calcula como en el login (`TRUSTED_PROXIES`).

**Por qué hace falta.** Sin él, cualquiera que llegue al servicio (incluido un cliente anónimo, o
cualquier IP contra el login) puede mandar peticiones sin freno. Cada petición cuesta: listar un bucket
recorre todo su directorio, `ListBuckets` recorre todos los objetos, cada subida calcula el md5 y
escribe en SQLite. Unos pocos clientes insistiendo bastan para saturarlo.

**Por qué el primero de los filtros.** Para cortar la avalancha antes de hacer trabajo: leer el
cuerpo, comprobar firmas SigV4 o JWT, consultar las reglas anónimas en SQLite.

**Por qué por IP y no por usuario.** El ataque que importa viene de quien no tiene credenciales; por
usuario no frenaría a un anónimo ni a alguien probando firmas.

### Por qué 2000 por minuto

Lo que manda es **no frenar nunca a un cliente legítimo**, porque los clientes S3 trabajan a ráfagas.
Para fijar el número se midió el tráfico real con un proxy delante del servicio (en Windows):

| Escenario | Peticiones | Pico en 1 s | Pico en 60 s |
|---|---:|---:|---:|
| Baterías completas (AWS CLI, rclone y las 15 suites de Mint) | 1373 en 142 s | 125 | **898** |
| `aws s3 sync` de 1000 ficheros pequeños (+ borrado del bucket) | 2004 en 108 s | 293 | **1532** |

- **Lo que dispara las peticiones son los ficheros pequeños en paralelo, no el multipart.** Un
  fichero grande por partes son pocas peticiones (una por parte de 8 MiB: un fichero de 1 GiB son
  ~130), mientras que `aws s3 sync` sube 10 ficheros a la vez y cada uno es al menos una petición.
  La consola también va en paralelo: 2 subidas y 2 descargas a la vez, más el listado por páginas.
- **2000/min deja margen sobre el peor caso medido (1532)** y sigue cortando una avalancha: un
  script en bucle hace miles de peticiones por segundo.
- **1000 se quedaría corto:** el `sync` de 1000 ficheros lo pasaría.

**Por qué `503 SlowDown` en la API S3 y no `429`.** Es lo que responde S3 cuando un cliente va
demasiado deprisa, y lo que los SDKs y la CLI de AWS reconocen como "espera y reintenta". La consola
no es un cliente S3 y va por la API de admin, que sigue con `429`.

**Qué le pasa a un cliente que llega al límite** (medido con el límite bajado a 100/min):

| Cliente | Con `429` (antes) | Con `503 SlowDown` (ahora) |
|---|---|---|
| AWS CLI v2 (`s3 sync` de 200 ficheros) | **No lo reintenta**: 102 ficheros fallan al momento con `Too Many Requests` | **Lo reintenta** (2 veces, con unos segundos de espera), pero con una ventana de 60 s no da tiempo: fallan los mismos 102 (`reached max retries: 2`) |
| rclone (`copy` de 200 ficheros) | Lo reintenta, muy lento | — |

Con `503 SlowDown` los clientes se portan como con S3, pero sus reintentos esperan segundos y la
ventana dura un minuto: **el límite no hace de regulador de caudal**. Por eso tiene que estar **por
encima de cualquier uso legítimo**: es un freno de emergencia contra abusos.

**Cuidado al ajustarlo.** Las medidas son en Windows, donde cada subida es lenta (Defender, SQLite).
En un servidor Linux rápido el mismo `sync` iría más deprisa y podría superar 2000/min. Si se
despliega para cargas masivas (migraciones, backups con muchos ficheros pequeños), hay que medir y
subirlo, o desactivarlo para las IPs de esos procesos. Pendiente de decidir (ver al final).

## 3. Firmas SigV4

| Decisión | Por qué |
|---|---|
| Una firma a más de **15 minutos** del reloj del servidor da `RequestTimeTooSkewed` (y la credencial tiene que ser del mismo día que la firma) | Sin ventana, una petición firmada capturada (por HTTP o en un log de un proxy) se podía repetir para siempre: en la revisión, una firmada hace 3 días funcionaba. 15 minutos es lo que usa S3 y tolera relojes algo desajustados |
| Una URL prefirmada no puede tener fecha futura | Con fecha futura se alargaba más allá del máximo de 7 días |
| Si el cliente firma el **sha256 del cuerpo**, se comprueba (`XAmzContentSHA256Mismatch`) | Si no, una petición capturada se podía repetir **con otro contenido**, y por HTTP alguien en medio podía cambiarlo. Se comprueba mientras se lee, sin cargar el cuerpo en memoria, y el objeto anterior no se toca si falla |
| Los cuerpos `UNSIGNED-PAYLOAD` y `aws-chunked` (`STREAMING-…`) no se comprueban | El cliente no firma el contenido en el primer caso; en el segundo habría que validar la firma de cada trozo. Queda en *Aparcado* (validación de checksums) |
| Los errores de autenticación no dan detalles internos | El mensaje de una excepción puede revelar la implementación |

## 4. Acceso anónimo

| Decisión | Por qué |
|---|---|
| Multipart nunca es anónimo (crear, partes, completar, abortar, listar subidas y partes) | Con una regla de escritura, un anónimo podía listar las subidas en curso de otros, sustituir sus partes o abortarlas. Las operaciones que van por rutas que aceptan reglas anónimas (PUT, DELETE, GET) exigen el permiso de subida explícitamente |
| Un anónimo no puede copiar (CopyObject, UploadPartCopy) ni cambiar las cabeceras de la respuesta (`response-*`) | Copiar lee el origen, que puede no estar cubierto por ninguna regla |
| El borrado múltiple nunca es anónimo | Sus keys van en el cuerpo y no se pueden comprobar contra las reglas antes de leerlo |

## 5. Otras decisiones de seguridad

| Decisión | Por qué |
|---|---|
| Los JWT tienen que llevar `exp` | Los que emite el servicio siempre caducan (12 h); un token sin `exp` (falsificado con el secreto) no caducaría nunca |
| Las keys no pueden contener `\` | En Windows es separador de carpetas: `a\b` era otra forma de escribir `a/b` y permitía escribir el marcador de carpeta |
| CORS acepta cualquier origen, sin credenciales | La autenticación va en la cabecera `Authorization` (JWT o SigV4), no en cookies: otra web no puede hacer peticiones en nombre del usuario |

## Pendiente de decidir

- **Subir el límite general por defecto** si se despliega en un servidor rápido o para cargas masivas
  (ver *Cuidado al ajustarlo*).
- Revisión de seguridad: límite más bajo para el tráfico anónimo, servir como descarga el HTML/JS que
  sube un anónimo (o dominios separados para el servicio y la consola), si `*` en las reglas anónimas
  debe anclar al final de la key, y `PUBLIC_URL` para las URLs prefirmadas en vez del `Host`.
