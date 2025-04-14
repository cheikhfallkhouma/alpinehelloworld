pipeline {
    agent any
    environment {
        PORT_EXPOSED = "80"
        IMAGE_NAME = 'alpinehelloworld'
        IMAGE_TAG = 'latest'
    }
    stages {
        stage('Build Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'DOCKERHUB_AUTH', usernameVariable: 'DOCKERHUB_AUTH', passwordVariable: 'DOCKERHUB_AUTH_PSW')]) {
                    sh '''
                        docker build -t ${DOCKERHUB_AUTH}/${IMAGE_NAME}:${IMAGE_TAG} .
                    '''
                }
            }
        }

        stage('Run container based on builded image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'DOCKERHUB_AUTH', usernameVariable: 'DOCKERHUB_AUTH', passwordVariable: 'DOCKERHUB_AUTH_PSW')]) {
                    sh '''
                        echo "Clean Environment"
                        docker rm -f $IMAGE_NAME || echo "container does not exist"
                        docker run --name $IMAGE_NAME -d -p ${PORT_EXPOSED}:5000 -e PORT=5000 ${DOCKERHUB_AUTH}/$IMAGE_NAME:$IMAGE_TAG
                        sleep 5
                    '''
                }
            }
        }

        stage('Test image') {
            steps {
                sh '''
                    curl http://172.17.0.1:${PORT_EXPOSED} | grep -q "Hello world!"
                '''
            }
        }
        stage('Deploy in staging') {
    environment {
        HOSTNAME_DEPLOY_STAGING = "54.145.215.204"
    }
    steps {
        sshagent(credentials: ['SSH_AUTH_SERVER']) {
            withCredentials([usernamePassword(credentialsId: 'DOCKERHUB_AUTH', usernameVariable: 'DOCKERHUB_AUTH', passwordVariable: 'DOCKERHUB_AUTH_PSW')]) {
                sh '''
                    # Assurer que le dossier .ssh existe et a les bonnes permissions
                    [ -d ~/.ssh ] || mkdir ~/.ssh && chmod 0700 ~/.ssh
                    ssh-keyscan -t rsa,dsa ${HOSTNAME_DEPLOY_STAGING} >> ~/.ssh/known_hosts
                    
                    # Ajouter l'utilisateur Jenkins au groupe docker si ce n'est pas déjà fait
                    if ! groups $(whoami) | grep -q '\bdocker\b'; then
                        echo "Ajout de l'utilisateur au groupe docker..."
                        sudo usermod -aG docker $(whoami)
                    fi
                    
                    # Vérifier que Docker est installé et en cours d'exécution
                    if ! command -v docker &> /dev/null; then
                        echo "Docker n'est pas installé. Installation en cours..."
                        sudo apt-get update
                        sudo apt-get install -y docker.io
                        sudo systemctl enable docker
                        sudo systemctl start docker
                    fi
                    
                    # Exécuter les commandes Docker
                    command1="sudo docker login -u $DOCKERHUB_AUTH -p $DOCKERHUB_AUTH_PSW"
                    command2="sudo docker pull $DOCKERHUB_AUTH/$IMAGE_NAME:$IMAGE_TAG"
                    command3="sudo docker rm -f webapp || echo 'app does not exist'"
                    command4="sudo docker run -d -p 80:5000 -e PORT=5000 --name webapp $DOCKERHUB_AUTH/$IMAGE_NAME:$IMAGE_TAG"
                    
                    # Exécuter les commandes sur le serveur distant
                    ssh -o StrictHostKeyChecking=no ubuntu@${HOSTNAME_DEPLOY_STAGING} "$command1 && $command2 && $command3 && $command4"
                '''
                    }
                }
            }
        }
    }
}
