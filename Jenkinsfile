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
        stage('linter'){
            steps{
                sh 'docker run --rm ${IMAGE}:${TAG} ruff check src tests'
            }
        }
        stage('unit tests') {
            steps{
                sh 'docker run --rm ${IMAGE}:${TAG} pytest -m "not integration"'
            }
        }
    }
    post {
        always { 
            sh 'docker rmi ${IMAGE}:${TAG} || true'
        }
    }
}
