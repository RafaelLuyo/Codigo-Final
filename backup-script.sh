#!/bin/bash
set -e

# ============================================
# Script de Backup para MySQL, PostgreSQL, MongoDB
# Sube backups a AWS S3: bucket-codigo-backup
# Subcarpeta: luyo-alumno/database/YYYYMMDDHHMMSS/
# ============================================

# Variables de entorno (se pasan desde el CronJob)
DB_DRIVER="${MY_DATABASE_DRIVER}"
DB_HOST="${DB_HOST}"
DB_USER="${DB_USER_NAME}"
DB_PASS="${DB_PASSWORD}"
DB_NAME="${DB_NAME}"
DB_PORT="${DB_PORT}"

# Configuración de AWS S3
AWS_BUCKET="bucket-codigo-backup-rafael"
SUBFOLDER="luyo-rafael/database"

# Generar timestamp con formato YYYYMMDDHHMMSS
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
BACKUP_DIR="${SUBFOLDER}/${TIMESTAMP}"

echo "=========================================="
echo "Iniciando backup de base de datos"
echo "Driver: ${DB_DRIVER}"
echo "Host: ${DB_HOST}"
echo "Database: ${DB_NAME}"
echo "Timestamp: ${TIMESTAMP}"
echo "Destino S3: s3://${AWS_BUCKET}/${BACKUP_DIR}/"
echo "=========================================="

# Función para backup MySQL
backup_mysql() {
    echo "[MySQL] Ejecutando mysqldump..."
    BACKUP_FILE="backup_mysql_${TIMESTAMP}.sql"
    mysqldump \
        -h "${DB_HOST}" \
        -P "${DB_PORT}" \
        -u "${DB_USER}" \
        -p"${DB_PASS}" \
        "${DB_NAME}" > "/tmp/${BACKUP_FILE}"
    
    if [ $? -eq 0 ]; then
        echo "[MySQL] Backup completado: ${BACKUP_FILE}"
    else
        echo "[MySQL] Error al crear backup"
        exit 1
    fi
}

# Función para backup PostgreSQL
backup_postgres() {
    echo "[PostgreSQL] Ejecutando pg_dump..."
    BACKUP_FILE="backup_postgres_${TIMESTAMP}.sql"
    export PGPASSWORD="${DB_PASS}"
    pg_dump \
        -h "${DB_HOST}" \
        -p "${DB_PORT}" \
        -U "${DB_USER}" \
        -d "${DB_NAME}" \
        -F p \
        > "/tmp/${BACKUP_FILE}"
    
    if [ $? -eq 0 ]; then
        echo "[PostgreSQL] Backup completado: ${BACKUP_FILE}"
    else
        echo "[PostgreSQL] Error al crear backup"
        exit 1
    fi
}

# Función para backup MongoDB
backup_mongo() {
    echo "[MongoDB] Ejecutando mongodump..."
    BACKUP_FILE="backup_mongo_${TIMESTAMP}.tar.gz"
    
    mongodump \
        --host "${DB_HOST}" \
        --port "${DB_PORT}" \
        --username "${DB_USER}" \
        --password "${DB_PASS}" \
        --authenticationDatabase admin \
        --db "${DB_NAME}" \
        --out "/tmp/mongo_backup_${TIMESTAMP}"
    
    if [ $? -eq 0 ]; then
        echo "[MongoDB] Dump completado, creando archivo comprimido..."
        tar -czf "/tmp/${BACKUP_FILE}" -C /tmp "mongo_backup_${TIMESTAMP}"
        rm -rf "/tmp/mongo_backup_${TIMESTAMP}"
        echo "[MongoDB] Backup completado: ${BACKUP_FILE}"
    else
        echo "[MongoDB] Error al crear backup"
        exit 1
    fi
}

# Ejecutar backup según el driver
case "${DB_DRIVER}" in
    mysql)
        backup_mysql
        ;;
    postgres)
        backup_postgres
        ;;
    mongo)
        backup_mongo
        ;;
    *)
        echo "ERROR: Driver '${DB_DRIVER}' no soportado"
        echo "Drivers soportados: mysql, postgres, mongo"
        exit 1
        ;;
esac

# Subir a S3
echo "=========================================="
echo "Subiendo backup a AWS S3..."
echo "Destino: s3://${AWS_BUCKET}/${BACKUP_DIR}/${BACKUP_FILE}"

aws s3 cp "/tmp/${BACKUP_FILE}" "s3://${AWS_BUCKET}/${BACKUP_DIR}/${BACKUP_FILE}"

if [ $? -eq 0 ]; then
    echo "Upload completado exitosamente!"
else
    echo "ERROR: Fallo al subir archivo a S3"
    exit 1
fi

# Limpiar archivos temporales
echo "Limpiando archivos temporales..."
rm -f "/tmp/${BACKUP_FILE}"

echo "=========================================="
echo "Backup completado exitosamente!"
echo "Archivo: s3://${AWS_BUCKET}/${BACKUP_DIR}/${BACKUP_FILE}"
echo "=========================================="# updated
