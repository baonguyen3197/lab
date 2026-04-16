pipeline {
  agent { label 'linux-01' }

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
            docker run --rm -i \
              --network jenkins \
              -e DOCKERHUB_USERNAME="$DOCKERHUB_USERNAME" \
              -e DOCKERHUB_PASSWORD="$DOCKERHUB_PASSWORD" \
              -e DOCKER_HOST=tcp://docker:2376 \
              -e DOCKER_TLS_VERIFY=1 \
              -e DOCKER_CERT_PATH=/certs/client \
              -v jenkins-docker-certs:/certs/client:ro \
              docker:27-cli sh -c "set -eu; apk add --no-cache pass gnupg wget; ARCH=\$(apk --print-arch); case \"\$ARCH\" in x86_64) HELPER_ARCH=amd64 ;; aarch64) HELPER_ARCH=arm64 ;; *) echo Unsupported arch: \$ARCH; exit 1 ;; esac; wget -qO /usr/local/bin/docker-credential-pass https://github.com/docker/docker-credential-helpers/releases/download/v0.9.5/docker-credential-pass-v0.9.5.linux-\$HELPER_ARCH; chmod +x /usr/local/bin/docker-credential-pass; export GNUPGHOME=/root/.gnupg; mkdir -p /root/.docker \$GNUPGHOME; chmod 700 \$GNUPGHOME; printf '{\\\"credsStore\\\":\\\"pass\\\"}' > /root/.docker/config.json; gpg --batch --passphrase '' --quick-generate-key 'test <test@local>' rsa2048 encrypt never || true; KEYID=\$(gpg --batch --with-colons --list-secret-keys | awk -F: '/^fpr:/ {print \$10; exit}' | tr -d '\\r\\n'); echo \"\$KEYID:6:\" | gpg --import-ownertrust; pass init \"\$KEYID\"; printf %s \"\$DOCKERHUB_PASSWORD\" | docker login -u \"\$DOCKERHUB_USERNAME\" --password-stdin; echo === CONFIG ===; cat /root/.docker/config.json; docker logout"
          '''
        }
      }
    }
  }
}