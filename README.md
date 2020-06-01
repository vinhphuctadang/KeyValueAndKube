# Key Value server and Kubenete deployment

## Structure:

**The system is composed of:**
- 3 pods running the main app (explore /app for details) with its static volume (node app won't make any changes to its volume).
- Sharded mongodb:
  The db system has:
  - 2 shards, 1 replica for each shard, 1 persistent volume for each replica
  - 2 config servers, with its own volume, no persistent volume (maybe bad practice)
  - 2 mongo router pod (mongos)
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
  Follow instruction here

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

Following lines will run (if you run ``./cmd.sh start`` then you won't need to run the next lines):
```
kubectl create namespace myserver
kubectl apply -f config/mongo/configserver.yaml -n myserver # start mongo config servers and their service
kubectl apply -f config/mongo/shard.yaml -n myserver # start 2 shards with persistent volumes
kubectl apply -f config/mongo/router.yaml -n myserver # start mongo router for exposing mongodb to our node app (app written in nodejs, in /app)

kubectl apply -f config/server.yaml -n myserver # start the node app, as a server configured in server.yaml
kubectl apply -f config/ingress.yaml -n myserver # ingress for accessing the server app over internet
```
3. Now just go to browser:


# Common failure:

## More about application deployment and devops???
