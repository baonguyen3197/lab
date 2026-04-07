pipeline {
  agent any

  environment {
    DOCKERHUB_CREDENTIALS_ID = 'dockerhub-creds'
  }

  stages {
    stage('Login to Docker Hub') {
      steps {
        withCredentials([
          usernamePassword(
            credentialsId: env.DOCKERHUB_CREDENTIALS_ID,
            usernameVariable: 'DOCKERHUB_USERNAME',
            passwordVariable: 'DOCKERHUB_PASSWORD'
          )
        ]) {
          sh '''
            echo "This is a test!" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
          '''
        }
      }
    }

    stage('Echo and Docker check') {
      steps {
        sh '''
          echo "Hello from Jenkins after Docker Hub login!"
          docker pull hello-world:latest
        '''
      }
    }
  }

  post {
    always {
      sh 'docker logout || true'
    }
  }
}
