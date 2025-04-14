 steps {
        sshagent(credentials: ['SSH_AUTH_SERVER']) {
            withCredentials([usernamePassword(credentialsId: 'DOCKERHUB_AUTH', usernameVariable: 'DOCKERHUB_AUTH', passwordVariable: 'DOCKERHUB_AUTH_PSW')]) {
                sh '''
                    [ -d ~/.ssh ] || mkdir ~/.ssh && chmod 0700 ~/.ssh
                    ssh-keyscan -t rsa,dsa ${HOSTNAME_DEPLOY_STAGING} >> ~/.ssh/known_hosts

                    ssh ubuntu@${HOSTNAME_DEPLOY_STAGING} '
                        # Nettoyage des installations cassées
                        sudo dpkg --configure -a
                        sudo apt-get install -f -y
                        
                        # Suppression Docker partiel si existant
                        sudo apt-get remove --purge -y docker docker.io docker-engine docker-ce docker-ce-cli containerd runc || true
                        sudo apt-get autoremove -y
                        sudo apt-get clean

                        # Installation via le script officiel Docker
                        curl -fsSL https://get.docker.com | sudo sh

                        # Ajout utilisateur au groupe docker (optionnel si nécessaire)
                        sudo usermod -aG docker ubuntu
                    '

                    # Commandes Docker après install
                    command1="docker login -u $DOCKERHUB_AUTH -p $DOCKERHUB_AUTH_PSW"
                    command2="docker pull $DOCKERHUB_AUTH/$IMAGE_NAME:$IMAGE_TAG"
                    command3="docker rm -f mywebapp || echo 'app does not exist'"
                    command4="docker run -d -p 8081:5000 -e PORT=5000 --name mywebapp $DOCKERHUB_AUTH/$IMAGE_NAME:$IMAGE_TAG"

                    ssh -o StrictHostKeyChecking=no ubuntu@${HOSTNAME_DEPLOY_STAGING} "$command1 && $command2 && $command3 && $command4"
                    
                        '''
                    }
                }
            }
        }
    }
}
