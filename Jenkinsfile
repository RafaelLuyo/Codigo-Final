pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'rafaelmao/node-codigo-rafael'
        BACKUP_IMAGE = 'rafaelmao/backup-jenkins'
        DEPLOY_PATH = '/codigo/luyo-rafael'
        DOCKER_CREDENTIALS = credentials('cc484cb0-e9e7-4dcf-b268-f6e38790dd8c')
        AWS_ACCESS_KEY_ID = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
        AWS_DEFAULT_REGION = credentials('aws-region')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "Código descargado desde rama: ${env.BRANCH_NAME}"
            }
        }
        
        stage('Build Backend Image') {
            steps {
                script {
                    sh """
                        docker build -t ${DOCKER_IMAGE}:latest .
                        docker build -t ${DOCKER_IMAGE}:${env.BUILD_NUMBER} .
                    """
                }
            }
        }
        
        stage('Build Backup Image') {
            steps {
                script {
                    sh """
                        docker build -f Dockerfile.backup.jenkins -t ${BACKUP_IMAGE}:latest .
                        docker build -f Dockerfile.backup.jenkins -t ${BACKUP_IMAGE}:${env.BUILD_NUMBER} .
                    """
                }
            }
        }
        
        stage('Push Images to Docker Hub') {
            steps {
                script {
                    sh """
                        echo ${DOCKER_CREDENTIALS_PSW} | docker login -u ${DOCKER_CREDENTIALS_USR} --password-stdin
                        docker push ${DOCKER_IMAGE}:latest
                        docker push ${DOCKER_IMAGE}:${env.BUILD_NUMBER}
                        docker push ${BACKUP_IMAGE}:latest
                        docker push ${BACKUP_IMAGE}:${env.BUILD_NUMBER}
                    """
                }
            }
        }
        
        stage('Create Deploy Directory') {
            steps {
                sh """
                    sudo mkdir -p ${DEPLOY_PATH}
                    sudo chown -R jenkins:jenkins ${DEPLOY_PATH}
                """
            }
        }
        
        stage('Deploy with Docker Compose') {
            steps {
                dir("${DEPLOY_PATH}") {
                    sh """
                        # Copiar archivos necesarios
                        cp ${WORKSPACE}/docker-compose.jenkins.yml docker-compose.yml
                        cp ${WORKSPACE}/env.jenkins.example .env
                        cp -r ${WORKSPACE}/data ./data 2>/dev/null || true
                        cp -r ${WORKSPACE}/script ./script 2>/dev/null || true
                        
                        # Detener contenedores existentes
                        docker-compose down --remove-orphans || true
                        
                        # Iniciar nuevos contenedores
                        docker-compose pull
                        docker-compose up -d
                        
                        # Esperar a que los servicios estén listos
                        sleep 30
                        
                        # Verificar estado
                        docker-compose ps
                    """
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    sh """
                        # Verificar que el backend responde
                        for i in 1 2 3 4 5; do
                            if curl -s http://localhost:3000/ > /dev/null; then
                                echo "Backend está funcionando correctamente"
                                exit 0
                            fi
                            echo "Intento \$i: Backend no responde, esperando..."
                            sleep 10
                        done
                        echo "ERROR: Backend no responde después de 5 intentos"
                        exit 1
                    """
                }
            }
        }
        
        stage('Run Backup') {
            steps {
                script {
                    sh """
                        # Ejecutar backup manualmente
                        docker run --rm \
                            --network codigo_luyo-rafael_app-network \
                            -e MY_DATABASE_DRIVER=postgres \
                            -e DB_HOST=postgres-db \
                            -e DB_PORT=5432 \
                            -e DB_NAME=database \
                            -e DB_USER_NAME=admin \
                            -e DB_PASSWORD=admin123 \
                            -e AWS_ACCESS_KEY_ID=\${AWS_ACCESS_KEY_ID} \
                            -e AWS_SECRET_ACCESS_KEY=\${AWS_SECRET_ACCESS_KEY} \
                            -e AWS_DEFAULT_REGION=\${AWS_DEFAULT_REGION} \
                            ${BACKUP_IMAGE}:latest
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo '¡Pipeline ejecutado exitosamente!'
            echo "Backend desplegado en: ${DEPLOY_PATH}"
            echo "Acceso: http://<IP-DEL-SERVIDOR>:3000"
        }
        failure {
            echo 'El pipeline falló. Revisar logs.'
        }
        always {
            // Limpiar imágenes dangling
            sh 'docker image prune -f || true'
        }
    }
}
