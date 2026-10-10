## Integration

For now the console ALWAYS uses JSON content negotiation and JWT for every operation, including the
S3 ones that support SigV4.

## Env (Console)

| Variable       | Required | Default  | Description                                                    |
|:---------------|:--------:|:--------:|:---------------------------------------------------------------|
| `SERVICE_URL`  | **Yes**  |    -     | URL of the backend service.                                    |
| `ADMIN_PREFIX` |    No    | `_admin` | Prefix of the admin API (it must match the service's).         |

Locally they live in `web/env.js` (`window.env`, gitignored). In the Docker image that file is
written when the container starts, from the variables of the same name.

## Docker

`Dockerfile` builds the web app with the Flutter of `.fvmrc` and serves it with nginx (gzip,
`no-cache` for `index.html`, `env.js` and the Flutter bootstrap files). From `console/`:

```bash
docker build -t feather-io-console .
docker run -p 8081:80 -e SERVICE_URL=http://localhost:8080 -e ADMIN_PREFIX=_admin feather-io-console
```

`SERVICE_URL` is the service as the **browser** sees it, not as the container does. To start the
service and the console together, see `docker-compose.yml` at the root of the repo.
