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


        stage('Load SSH Key') {
            steps {
                sh '''
                    eval $(ssh-agent -s)
                    ssh-add /path/to/private_key
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
                            [ -d ~/.ssh ] || mkdir ~/.ssh && chmod 0700 ~/.ssh
                            ssh-keyscan -t rsa,dsa ${HOSTNAME_DEPLOY_STAGING} >> ~/.ssh/known_hosts
                            command1="docker login -u $DOCKERHUB_AUTH -p $DOCKERHUB_AUTH_PSW"
                            command2="docker pull $DOCKERHUB_AUTH/$IMAGE_NAME:$IMAGE_TAG"
                            command3="docker rm -f webapp || echo 'app does not exist'"
                            command4="docker run -d -p 80:5000 -e PORT=5000 --name webapp $DOCKERHUB_AUTH/$IMAGE_NAME:$IMAGE_TAG"
                            ssh -o StrictHostKeyChecking=no ubuntu@${HOSTNAME_DEPLOY_STAGING} "$command1 && $command2 && $command3 && $command4"
                        '''
                    }
                }
            }
        }
    }
}
