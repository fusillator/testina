pipeline {
    
    agent any
    
    environment {
        IMAGE="fusillator/flask-demo"
        TAG="${env.GIT_COMMIT}-${env.BUILD_NUMBER}"
    }
    
    stages{
        stage('build an ephemeral preview for ci test'){
            steps{
                sh '''
                    docker logout
                    docker build --target dev -t ${IMAGE}:${TAG} .
                '''
            }
        }
        stage('Unit tests') {
            steps {
                sh 'docker run --rm ${IMAGE}:${TAG} pytest'
            }
        }
    }
    post {
        always { 
            sh 'docker rmi ${IMAGE}:${TAG} || true'
        }
    }
}
