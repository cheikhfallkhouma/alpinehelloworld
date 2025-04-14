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
                withCredentials([usernamePassword(
                    credentialsId: 'DOCKERHUB_AUTH',
                    usernameVariable: 'DOCKERHUB_AUTH',
                    passwordVariable: 'DOCKERHUB_AUTH_PSW'
                )]) {
                    sh '''
                        docker build -t ${DOCKERHUB_AUTH}/${IMAGE_NAME}:${IMAGE_TAG} .
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
                HOSTNAME_DEPLOY_STAGING = "54.145.215.204"
            }
            steps {
                sshagent(credentials: ['SSH_AUTH_SERVER']) {
                    withCredentials([usernamePassword(
                        credentialsId: 'DOCKERHUB_AUTH',
                        usernameVariable: 'DOCKERHUB_AUTH',
                        passwordVariable: 'DOCKERHUB_AUTH_PSW'
                    )]) {
                        sh '''
                            export DOCKERHUB_AUTH_USR=$DOCKERHUB_AUTH
                            export DOCKERHUB_AUTH_PSW=$DOCKERHUB_AUTH_PSW

                            # Vérification et nettoyage des variables
                            DOCKERHUB_AUTH_USR=$(echo "$DOCKERHUB_AUTH_USR" | xargs)
                            IMAGE_NAME=$(echo "$IMAGE_NAME" | xargs)
                            IMAGE_TAG=$(echo "$IMAGE_TAG" | xargs)

                            echo "DOCKERHUB_AUTH_USR=$DOCKERHUB_AUTH_USR"
                            echo "IMAGE_NAME=$IMAGE_NAME"
                            echo "IMAGE_TAG=$IMAGE_TAG"
                            echo "Image: ${DOCKERHUB_AUTH_USR}/${IMAGE_NAME}:${IMAGE_TAG}"

                            # Création du répertoire ~/.ssh si nécessaire
                            [ -d ~/.ssh ] || mkdir -p ~/.ssh && chmod 0700 ~/.ssh
                            ssh-keyscan -H $HOSTNAME_DEPLOY_STAGING >> ~/.ssh/known_hosts

                            # Installation de Docker sur l'hôte distant
                            ssh ubuntu@$HOSTNAME_DEPLOY_STAGING "
                                sudo dpkg --configure -a;
                                sudo apt-get install -f -y;
                                sudo apt-get remove --purge -y docker docker.io docker-engine docker-ce docker-ce-cli containerd runc || true;
                                sudo apt-get autoremove -y;
                                sudo apt-get clean;
                                curl -fsSL https://get.docker.com | sudo sh;
                                sudo usermod -aG docker ubuntu
                            "

                            # Affichage de l'image avant d'essayer de la récupérer
                            echo "Image to pull: ${DOCKERHUB_AUTH_USR}/${IMAGE_NAME}:${IMAGE_TAG}"

                            # Docker login et déploiement de l'application
                            ssh ubuntu@$HOSTNAME_DEPLOY_STAGING '
                                echo "${DOCKERHUB_AUTH_PSW}" | docker login -u "${DOCKERHUB_AUTH_USR}" --password-stdin &&
                                docker pull "${DOCKERHUB_AUTH_USR}/${IMAGE_NAME}:${IMAGE_TAG}" &&
                                docker rm -f webapp || echo "app does not exist" &&
                                docker run -d -p 80:5000 -e PORT=5000 --name webapp "${DOCKERHUB_AUTH_USR}/${IMAGE_NAME}:${IMAGE_TAG}"
                            '
                        '''
                    }
                }
            }
        }
    }
}
