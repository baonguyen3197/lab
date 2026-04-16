# ====================== --- Note --- ====================== #
# This script is for demo, and setup Jenkins in both demo-1 & demo-2.

# ========================================================== #
# Create a Docker network for Jenkins and Docker-in-Docker
docker network create jenkins

docker run --name jenkins-docker --rm --detach `
  --privileged --network jenkins --network-alias docker `
  --env DOCKER_TLS_CERTDIR=/certs `
  --volume jenkins-docker-certs:/certs/client `
  --volume jenkins-data:/var/jenkins_home `
  --publish 2376:2376 `
  docker:dind

# --- # --- # --- # --- # --- # --- # --- # --- # Without credentials helper
# Build
docker build -t myjenkins-blueocean:2.541.3 .

# Run
docker run --name jenkins-blueocean --restart=on-failure --detach `
  --network jenkins --env DOCKER_HOST=tcp://docker:2376 `
  --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 `
  --volume jenkins-data:/var/jenkins_home `
  --volume jenkins-docker-certs:/certs/client:ro `
  --publish 8080:8080 --publish 50000:50000 myjenkins-blueocean:2.541.3


# --- # --- # --- # --- # --- # --- # --- # --- # With credentials helper
# Build
docker build -f Dockerfile.after -t myjenkins-blueocean:2.541.3-1 .

# Run
docker run --name jenkins-blueocean-1 --restart=on-failure --detach `
  --network jenkins --env DOCKER_HOST=tcp://docker:2376 `
  --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 `
  --volume jenkins-data-1:/var/jenkins_home `
  --volume jenkins-docker-certs:/certs/client:ro `
  --publish 8081:8080 --publish 50001:50000 myjenkins-blueocean:2.541.3-1