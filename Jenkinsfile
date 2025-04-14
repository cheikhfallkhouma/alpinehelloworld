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
                        # Export des variables pour qu'elles soient disponibles dans l'environnement de l'utilisateur Jenkins
                        export DOCKERHUB_AUTH_USR=$DOCKERHUB_AUTH
                        export DOCKERHUB_AUTH_PSW=$DOCKERHUB_AUTH_PSW
                        export IMAGE_NAME=$IMAGE_NAME
                        export IMAGE_TAG=$IMAGE_TAG
        
                        [ -d ~/.ssh ] || mkdir ~/.ssh && chmod 0700 ~/.ssh
                        ssh-keyscan -t rsa,dsa ${HOSTNAME_DEPLOY_STAGING} >> ~/.ssh/known_hosts
        
                        # Préparation du serveur (install Docker, clean)
                        ssh -t \
                            -o SendEnv=DOCKERHUB_AUTH_USR \
                            -o SendEnv=DOCKERHUB_AUTH_PSW \
                            -o SendEnv=IMAGE_NAME \
                            -o SendEnv=IMAGE_TAG \
                            ubuntu@${HOSTNAME_DEPLOY_STAGING} '
                                sudo dpkg --configure -a
                                sudo apt-get install -f -y
                                sudo apt-get remove --purge -y docker docker.io docker-engine docker-ce docker-ce-cli containerd runc || true
                                sudo apt-get autoremove -y
                                sudo apt-get clean
                                curl -fsSL https://get.docker.com | sudo sh
                                sudo usermod -aG docker ubuntu
                            '
        
                        # Lancement du container avec les variables d'env transmises via SendEnv
                        ssh -t \
                            -o SendEnv=DOCKERHUB_AUTH_USR \
                            -o SendEnv=DOCKERHUB_AUTH_PSW \
                            -o SendEnv=IMAGE_NAME \
                            -o SendEnv=IMAGE_TAG \
                            ubuntu@${HOSTNAME_DEPLOY_STAGING} '
                                docker login -u $DOCKERHUB_AUTH_USR -p $DOCKERHUB_AUTH_PSW &&
                                docker pull $DOCKERHUB_AUTH_USR/$IMAGE_NAME:$IMAGE_TAG &&
                                docker rm -f mywebapp || echo "app does not exist" &&
                                docker run -d -p 8081:5000 -e PORT=5000 --name mywebapp $DOCKERHUB_AUTH_USR/$IMAGE_NAME:$IMAGE_TAG
                            '
                    '''              
                    }
                }
            }
        }
    }
}
