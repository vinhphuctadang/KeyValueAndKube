# Key Value server and Kubernetes deployment

## Structure:

**The system is composed of:**
- 2 pods running the main app (explore /app for details) with its static volume (node app won't make any changes to its volume).
- Sharded mongodb:
  The db system has:
  - a config volume for storing scripts of mongo init
  - 2 shards, 2 replica for each shard, 1 persistent volume for each replica
  - 2 config servers, with its own volume, no persistent volume (maybe bad practice)
  - 2 mongo router pods (mongos)
  - a mongo service

## To execute:
First look at the following notes:
### Config files details:

- ``config/server.yaml`` includes:
  - Server deployment
  - Service of that deployment

- ``config/ingress.yaml`` includes:
  - Ingress for users to access the app, in server.yaml via internet

- ``config/mongo/configserver.yaml`` includes:
  - A statefulSet of mongodb configserver, kubernetes will generate 2 replica with names ``mongod-configdb-0`` and ``mongod-configdb-1``
  - A service to expose that statefulset to cluster
- ``config/mongo/router.yaml`` includes:
  - A deployment of mongodb router (mongos), kubernetes will generate 2 replica with prefix ``mongos``
  - A service to expose the deployment to cluster, as 'mongo'
### Now, following are build steps:
**Prerequisite:**
- docker

  ``sudo apt install docker.io``

- kubectl and minikube (for local tests):
  Please follow instruction on kubernetes.io homepage

  - An account on ``hub.docker.com`` if you would like to explore **step 1**

**Steps for app deployment**
1. Generate app image (optional, means that you could skip this step as you do not care about containerizing step, I've built an image for following step):
  - I have a Dockerfile which describe and build our 'app' image, just run ``./cmd.sh build``

  *Notes: In ./cmd.sh build, the script uses my own credentials (as vinhphuctadang) for logging into 'dockerhub' to push image onto the hub; to make it your own, please custom the name 'vinhphuctadang' to your 'dockerhub' account in order to have the built image pushed, and if you made changes, you should then edit config/server.yaml for correct image which matches your built image*


  **Modify config/server.yaml if you build your own image, at the line where**
```
  image: vinhphuctadang/key-value-server:latest
```
2. Run commands:
Simply run
```
./cmd.sh start
```

**Notes:** In case the 'mongo' init failed due to mongo component not finishing their booting actions, we should run ``./cmd.sh initMongo`` again

3. Inspect the address of our server ingress:
  ``kubectl get ingress -n myserver`` (since our namespace has only one ingress, there is only one externally visible IP address)

Example:
```
NAME                CLASS    HOSTS   ADDRESS      PORTS   AGE
key-value-ingress   <none>   *       172.17.0.3   80      21m
```
4. Stop server:
```
./cmd.sh stop
./cmd.sh clean
```
# Common failure:
- Kubectl not found => Check for kubectl installation on kubectl homepage
- You see the line:
``In case this script failed, mostly because components are not booting up completely, you should run ./cmd.sh mongoInit again``, first you should check if all mongo components are initialized properly or not, then if something looks like error, you should run ``./cmd.sh mongoInit``
- You cannot find the server IP:
Simply type ``./cmd.sh ingress`` then it should show the IP where you could have access to

## More about application deployment and devops???
Inbox me via Skype: worldhello1604@outlook.com
