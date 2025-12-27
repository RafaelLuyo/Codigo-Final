# Configuración de Jenkins en GCP

## 1. Crear VM en GCP

```bash
# Crear instancia de Compute Engine
gcloud compute instances create jenkins-server \
    --zone=us-central1-a \
    --machine-type=e2-medium \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud \
    --boot-disk-size=30GB \
    --tags=jenkins,http-server,https-server

# Abrir puertos necesarios
gcloud compute firewall-rules create allow-jenkins \
    --allow tcp:8080,tcp:3000 \
    --target-tags=jenkins
```

## 2. Instalar Docker en la VM

```bash
# Conectar a la VM
gcloud compute ssh jenkins-server --zone=us-central1-a

# Instalar Docker
sudo apt update
sudo apt install -y docker.io docker-compose
sudo systemctl enable docker
sudo systemctl start docker

# Agregar usuario al grupo docker
sudo usermod -aG docker $USER
```

## 3. Instalar Jenkins

```bash
# Instalar Java
sudo apt install -y openjdk-17-jdk

# Agregar repo de Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Instalar Jenkins
sudo apt update
sudo apt install -y jenkins

# Iniciar Jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Obtener password inicial
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

## 4. Configurar Jenkins

1. Acceder a `http://<IP-DE-LA-VM>:8080`
2. Ingresar el password inicial
3. Instalar plugins sugeridos
4. Crear usuario admin
5. Configurar URL de Jenkins

## 5. Agregar Credenciales

En **Jenkins → Manage Jenkins → Credentials**:

| ID | Tipo | Descripción |
|----|------|-------------|
| `dockerhub-credentials` | Username/Password | Usuario y token de Docker Hub |
| `aws-credentials` | Secret text | AWS_ACCESS_KEY_ID |
| `aws-secret` | Secret text | AWS_SECRET_ACCESS_KEY |

## 6. Crear Pipeline

1. **New Item** → Nombre: `backend-codigo`
2. Tipo: **Multibranch Pipeline**
3. Branch Sources: **GitHub**
4. Repository: `https://github.com/RafaelLuyo/Codigo-Final.git`
5. Behaviors: Discover branches → **jenkins**
6. Build Configuration: **Jenkinsfile**
7. Save

## 7. Agregar usuario jenkins al grupo docker

```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

## 8. Crear carpeta de despliegue

```bash
sudo mkdir -p /codigo/luyo-rafael
sudo chown -R jenkins:jenkins /codigo/luyo-rafael
```

## 9. Ejecutar Pipeline

1. Ir al job `backend-codigo`
2. Click en la rama `jenkins`
3. Click en **Build Now**

## Estructura Desplegada

```
/codigo/luyo-rafael/
├── docker-compose.yml
├── .env
├── data/
│   └── postgres_data.sql
└── script/
    └── initdb.sh
```

## Acceso

- **Jenkins**: http://<IP>:8080
- **Backend**: http://<IP>:3000

## Backup

Los backups se suben a:
`s3://bucket-codigo-backup-rafael/luyo-rafael/database-jenkins/YYYYMMDDHHMMSS/`
