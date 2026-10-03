## Integration

For now the console ALWAYS uses JSON content negotiation and JWT for every operation, including the
S3 ones that support SigV4.

## Env (Console)

| Variable       | Required | Default  | Description                                                    |
|:---------------|:--------:|:--------:|:---------------------------------------------------------------|
| `SERVICE_URL`  | **Yes**  |    -     | URL of the backend service.                                    |
| `ADMIN_PREFIX` |    No    | `_admin` | Prefix of the admin API (it must match the service's).         |
