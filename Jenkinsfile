pipeline {
    agent any
    
    environment {
        PORT_EXPOSED = "80"
        IMAGE_NAME = 'alpinehelloworld'
        IMAGE_TAG = 'latest'
    }

    stages {
        stage('Build Image and push image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'DOCKERHUB_AUTH',
                    usernameVariable: 'DOCKERHUB_AUTH',
                    passwordVariable: 'DOCKERHUB_AUTH_PSW'
                )]) {
                    sh '''
                        echo "${DOCKERHUB_AUTH_PSW}" | docker login -u "${DOCKERHUB_AUTH}" --password-stdin
                        docker build -t ${DOCKERHUB_AUTH}/${IMAGE_NAME}:${IMAGE_TAG} .
                        docker push ${DOCKERHUB_AUTH}/${IMAGE_NAME}:${IMAGE_TAG}            
                    '''
                }
            }
        }

        stage('Run container based on built image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'DOCKERHUB_AUTH',
                    usernameVariable: 'DOCKERHUB_AUTH',
                    passwordVariable: 'DOCKERHUB_AUTH_PSW'
                )]) {
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
                HOSTNAME_DEPLOY_STAGING = "18.209.4.173"
            }
            steps {
                sshagent(credentials: ['SSH_AUTH_SERVER']) {
                    withCredentials([usernamePassword(
                        credentialsId: 'DOCKERHUB_AUTH',
                        usernameVariable: 'DOCKERHUB_AUTH',
                        passwordVariable: 'DOCKERHUB_AUTH_PSW'
                    )]) {
                        sh '''
                            # S'assurer que le dossier .ssh existe
                            [ -d ~/.ssh ] || mkdir -p ~/.ssh && chmod 0700 ~/.ssh
                            ssh-keyscan -t rsa,dsa ${HOSTNAME_DEPLOY_STAGING} >> ~/.ssh/known_hosts

                            # Vérification si Docker est installé, si ce n'est pas le cas, installation
                            ssh ubuntu@${HOSTNAME_DEPLOY_STAGING} "
                                if ! command -v docker &> /dev/null; then
                                    echo 'Docker non installé, installation via script officiel...'
                                    curl -fsSL https://get.docker.com | sh
                                fi

                                # Démarrer Docker si nécessaire
                                if ! pgrep dockerd > /dev/null; then
                                    echo 'Démarrage du daemon Docker...'
                                    sudo systemctl start docker
                                fi

                                # Ajouter l'utilisateur ubuntu au groupe docker
                                sudo usermod -aG docker ubuntu
                            "
                            
                            # Affichage de l'image avant de la récupérer
                            echo "Image to pull: ${DOCKERHUB_AUTH}/${IMAGE_NAME}:${IMAGE_TAG}"

                            # Commandes Docker à exécuter à distance
                            ssh ubuntu@${HOSTNAME_DEPLOY_STAGING} "
                                docker login -u '${DOCKERHUB_AUTH}' -p '${DOCKERHUB_AUTH_PSW}' &&
                                docker pull '${DOCKERHUB_AUTH}/${IMAGE_NAME}:${IMAGE_TAG}' &&
                                docker rm -f webapp || echo 'app does not exist' &&
                                docker run -d -p 80:5000 -e PORT=5000 --name webapp '${DOCKERHUB_AUTH}/${IMAGE_NAME}:${IMAGE_TAG}'
                                sleep 3 &&
                                docker ps -a --filter name=webapp &&
                                docker logs webapp
                            "
                        '''
                    }
                }
            }
        }

        stage('Deploy in production') {
            environment {
                HOSTNAME_DEPLOY_PROD = "54.172.219.101"
            }
            steps {
                sshagent(credentials: ['SSH_AUTH_SERVER']) {
                    withCredentials([usernamePassword(
                        credentialsId: 'DOCKERHUB_AUTH',
                        usernameVariable: 'DOCKERHUB_AUTH',
                        passwordVariable: 'DOCKERHUB_AUTH_PSW'
                    )]) {
                        sh '''
                            echo "Ajout de la clé SSH du serveur de production"
                            [ -d ~/.ssh ] || mkdir -p ~/.ssh && chmod 0700 ~/.ssh
                            ssh-keyscan -t rsa,dsa ${HOSTNAME_DEPLOY_PROD} >> ~/.ssh/known_hosts

                            ssh ubuntu@${HOSTNAME_DEPLOY_PROD} "
                                if ! command -v docker &> /dev/null; then
                                    echo 'Docker non installé. Installation en cours...'
                                    curl -fsSL https://get.docker.com | sh
                                fi

                                sudo systemctl start docker || true
                                sudo usermod -aG docker ubuntu

                                echo '${DOCKERHUB_AUTH_PSW}' | sudo docker login -u '${DOCKERHUB_AUTH}' --password-stdin
                                sudo docker pull '${DOCKERHUB_AUTH}/${IMAGE_NAME}:${IMAGE_TAG}'
                                sudo docker rm -f prodapp || echo 'prodapp does not exist'
                                sudo docker run -d -p 443:5000 -e PORT=5000 --name prodapp '${DOCKERHUB_AUTH}/${IMAGE_NAME}:${IMAGE_TAG}'
                                sleep 3
                                sudo docker ps -a --filter name=prodapp
                                sudo docker logs prodapp
                            "
                        '''
                    }
                }
            }
        }
    }
}
