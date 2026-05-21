# **Install docker-credential-helpers**

## Manual Setup

```
# Java
sudo apt install openjdk-21-jre-headless

# docker-credential-helpers
sudo apt install golang-docker-credential-helpers

# Verify
java -version
docker-credential-pass list
```

## Config

### Init gpg key

```
# Gen key
gpg --full-generate-key

# Get key id
gpg --list-secret-keys --keyid-format LONG

sec   ed25519/B9A13E54DC976DAE 2026-04-27 [SC]
      D85A04***76DAE # this is key id
```

### Setup pass

```
# Install pass
sudo apt install pass

# Init pass
pass init D85A04***76DAE
```

**Notes**:

- After setup pass, must **logout** then **login** again to apply new changes.
- `docker logout`
- `docker login -u ${USERNAME} 	# Follow docker step to login via terminal.`

## Verify

```
# Verify docker config
cat .docker/config.json

{
        "auths": {
                "https://index.docker.io/v1/": {},
                "https://index.docker.io/v1/access-token": {},
                "https://index.docker.io/v1/refresh-token": {}
        },
        "credsStore": "pass"
}

# Verify docker-credential-helpers
docker-credential-pass list
{"https://index.docker.io/v1/":"{$DOCKERHUB_USERNAME}","https://index.docker.io/v1/access-token":"{$DOCKERHUB_USERNAME}","https://index.docker.io/v1/refresh-token":"{$DOCKERHUB_USERNAME}"}
```

After completing this setup, you can directly use `docker push` and `docker pull` without needing to wrap commands in `withCredentials`.

```
Started by user admin
[Pipeline] Start of Pipeline
[Pipeline] node
Running on nhqb in /home/nhqb/workspace/workspace/test
[Pipeline] {
[Pipeline] withEnv
[Pipeline] {
[Pipeline] stage
[Pipeline] { (Docker Pull via pass helper)
[Pipeline] sh
+ set +x
1.0.0: Pulling from nhqb3197/db-service
Digest: sha256:baa7fa494f40d186883314f117d2c02795ea08972337f78e27139ff15b6ba1e4
Status: Image is up to date for nhqb3197/db-service:1.0.0
docker.io/nhqb3197/db-service:1.0.0
Password is 
Debug mode: sleeping for 60 seconds before job ends
[Pipeline] }
[Pipeline] // stage
[Pipeline] }
[Pipeline] // withEnv
[Pipeline] }
[Pipeline] // node
[Pipeline] End of Pipeline
Finished: SUCCESS
```
