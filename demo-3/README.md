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

sec   ed25519/B9***AE 2026-04-27 [SC]   # this is key id in short format
      D85A04***76DAE 			# this is key id in long format
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

---

# Usage of Automation script

There are 3 scripts for this setup:

* `install-docker-credentials.sh`		-> Install + config gpg key + init pass
* `check-docker-keys.sh`			-> Verify dependencies + key configured
* `cleanup-docker-credentials.sh`*
      ->* Uninstall all dependencies + remove keys + remove docker config file

## Script arguments

Use `install-docker-credentials.sh` with flags.

### Flags

* `-u`, `--username` sets the GPG real name that will be used when generating the key.
* `-e`, `--email` sets the GPG email address attached to the key.
* `-d`, `--dir` sets the credentials directory where `.gnupg`, `.password-store`, and `.docker` will be created.
* `-h`, `--help` prints the built-in usage help and exits.

### Default values

These are default value set in the `install-docker-credentials.sh` script. Please change it based on your desired setting.

* Username: `John Doe`
* Email: `john@example.com`
* Directory: current folder `.`

#### Examples

```
# Use the default values
./install-docker-credentials.sh

# Set a custom name and email
./install-docker-credentials.sh -u john -e john@example.com

# Set a custom name, email, and credentials directory
./install-docker-credentials.sh -u "John Doe" -e john@example.com -d /home/john/Desktop
```

## Usage

```
# Install & configure docker-credential-helper
# By default
chmod +x install-docker-credentials.sh
./install-docker-credentials.sh

# Verify + check status
chmod +x check-docker-keys.sh
./check-docker0keys.sh

# Cleanup / Remove config
chmod +x cleanup-dockr-credentials.sh
./cleanup-docker-credentials.sh

```
