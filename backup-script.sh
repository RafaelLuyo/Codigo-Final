#!/bin/bash

# Variables de entorno (se pasan desde el CronJob)
DB_DRIVER=$MY_DATABASE_DRIVER
DB_HOST=$DB_HOST
DB_USER=$DB_USER_NAME
DB_PASS=$DB_PASSWORD
DB_NAME=$DB_NAME
DB_PORT=$DB_PORT
AWS_BUCKET="bucket-codigo-backup"
SUBFOLDER="luyo-alumno/database"

# Generar timestamp
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
BACKUP_DIR="$SUBFOLDER/$TIMESTAMP"
BACKUP_FILE="backup_$TIMESTAMP.sql"  # Para SQL, o .bson para Mongo

# Función para backup MySQL
backup_mysql() {
    mysqldump -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME > /tmp/$BACKUP_FILE
}

# Función para backup Postgres
backup_postgres() {
    export PGPASSWORD=$DB_PASS
    pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME > /tmp/$BACKUP_FILE
}

# Función para backup MongoDB
backup_mongo() {
    mongodump --host $DB_HOST --port $DB_PORT --username $DB_USER --password $DB_PASS --db $DB_NAME --out /tmp/mongo_backup
    # Para Mongo, es un directorio, así que zippearlo
    tar -czf /tmp/$BACKUP_FILE.tar.gz -C /tmp mongo_backup
    BACKUP_FILE="$BACKUP_FILE.tar.gz"
}

# Ejecutar backup según driver
case $DB_DRIVER in
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
        echo "Driver no soportado"
        exit 1
        ;;
esac

# Subir a S3
aws s3 cp /tmp/$BACKUP_FILE s3://$AWS_BUCKET/$BACKUP_DIR/$BACKUP_FILE

# Limpiar
rm -f /tmp/$BACKUP_FILE