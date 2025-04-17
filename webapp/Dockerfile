version: '4'
services:
  jenkins:
    privileged: true
    user: root
    container_name: jenkins-launch
    image: jenkins/jenkins:2.490-jdk17
    restart: always
    ports:
      - 8080:8080
      - 50000:50000
    volumes:
      - /usr/bin/docker:/usr/bin/docker 
      - jenkins_launch:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock      
volumes:
 jenkins_launch:
