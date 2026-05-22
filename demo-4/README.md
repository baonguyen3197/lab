First test using Jenkins script:

```
Started by user admin

[Pipeline] Start of Pipeline
[Pipeline] node
Running on Jenkins
 in /var/jenkins_home/workspace/nhqb-pipeline
[Pipeline] {
[Pipeline] stage
[Pipeline] { (Example 1)
[Pipeline] sh
+ echo This is wrong
This is wrong
[Pipeline] sh
+ echo hello
hello
+ ls /
bin
boot
certs
dev
etc
home
lib
lib64
media
mnt
opt
proc
root
run
sbin
srv
sys
tmp
usr
var
[Pipeline] sh
+ echo This is correct
This is correct
[Pipeline] sh
+ echo hello; ls /
hello; ls /
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Example 2)
[Pipeline] sh
+ echo This is also correct
This is also correct
+ echo hello; ls /
hello; ls /
[Pipeline] }
[Pipeline] // stage
[Pipeline] }
[Pipeline] // node
[Pipeline] End of Pipeline
Finished: SUCCESS

```
