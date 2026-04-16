pipeline {
  agent any

  environment {
    DOCKERHUB_CREDENTIALS_ID = 'dockerhub-cred'
  }

  stages {
    stage('Test Docker Login CLI') {
      steps {
        withCredentials([
          usernamePassword(
            credentialsId: env.DOCKERHUB_CREDENTIALS_ID,
            usernameVariable: 'DOCKERHUB_USERNAME',
            passwordVariable: 'DOCKERHUB_PASSWORD'
          )
        ]) {
          sh '''
            set +x
            printf '%s' "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
            docker logout
            set -x
          '''
        }
      }
    }

    stage('Test withCredentials Ops') {
      steps {
        withCredentials([
          usernamePassword(
            credentialsId: env.DOCKERHUB_CREDENTIALS_ID,
            usernameVariable: 'DOCKERHUB_USERNAME',
            passwordVariable: 'DOCKERHUB_PASSWORD'
          )
        ]) {
          sh '''
            set +x
            printf '%s' "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
            echo "Hello from Jenkins after Docker Hub login!"
            docker logout
            sleep 120
            set -x
          '''
        }
      }
    }
  }

}