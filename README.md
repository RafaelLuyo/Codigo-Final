# Backend con Kubernetes - Proyecto Código

## Descripción
Proyecto backend Node.js desplegado en Kubernetes (GKE) con soporte para MySQL, PostgreSQL y MongoDB.

## Estructura del Proyecto

```
ProyectoBackend/
├── k8s/
│   ├── base/                    # Recursos base
│   │   ├── namespace.yaml
│   │   ├── configmap.yaml
│   │   └── secret.yaml
│   ├── backend/                 # Aplicación backend (2 réplicas)
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── databases/               # Bases de datos
│   │   ├── postgres/
│   │   ├── mysql/
│   │   └── mongo/
│   └── cronjobs/                # Jobs programados
│       └── backup-cronjob.yaml
├── .github/workflows/
│   └── deploy.yml               # CI/CD para GKE
├── Dockerfile                   # Imagen del backend
├── Dockerfile.backup            # Imagen para backups
└── backup-script.sh             # Script de backup a S3
```

## Secretos de GitHub Actions (REQUERIDOS)

Configura estos secretos en **Settings → Secrets and variables → Actions**:

| Secret | Descripción |
|--------|-------------|
| `DOCKERHUB_USERNAME` | Usuario de Docker Hub |
| `DOCKERHUB_TOKEN` | Token de acceso de Docker Hub |
| `AWS_ACCESS_KEY_ID` | AWS Access Key para S3 |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key para S3 |
| `AWS_DEFAULT_REGION` | Región de AWS (sa-east-1) |

## Despliegue

1. Configura los secretos en GitHub
2. Haz push a la rama `develop`
3. El workflow automáticamente:
   - Construye las imágenes Docker
   - Las sube a Docker Hub
   - Despliega en GKE

## CronJob de Backup

Se ejecuta cada 3 horas y sube a: `s3://bucket-codigo-backup/luyo-alumno/database/YYYYMMDDHHMMSS/`

## Cambiar Base de Datos

Edita `k8s/base/configmap.yaml`:
```yaml
data:
  MY_DATABASE_DRIVER: "mysql"  # postgres, mysql, mongo
  DB_HOST: "mysql-service"
  DB_PORT: "3306"
```
