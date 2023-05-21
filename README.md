# Collection of Dockerfiles for software developers' daily use

## Dockerfile.ssh
For building an ubuntu docker with ssh login capability. 

### Related files
* user.dat - a list of username and password pair
* include.pkg - deb packages you want to install 
* include.pip3.pkg - pip packages you want to install 

### How to use
* edit user.dat, include.pkg and include.pip3.pkg to fit your needs.
* run ./build.sh
  ```bash
  ./build.sh --build --verbose
  ```
* You can use build.sh to start the docker image
  ``` bash
  ./build.sh --run
  ```
* You can use build.sh to prune the docker image
  ```bash
  ./build.sh --prune
  ```



