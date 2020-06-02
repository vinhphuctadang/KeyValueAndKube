
# CONSTANTS
MONGO_CFG_SERVER="k8s/dev/mongo/configserver.yaml" # config for mongo config server
MONGO_SHARD="k8s/dev/mongo/shard.yaml" # config for mongo shards
MONGO_ROUTER="k8s/dev/mongo/router.yaml"

MUTAL_VOLUME="k8s/dev/config-volume.yaml"
SERVER="k8s/dev/server.yaml"
INGRESS="k8s/dev/ingress.yaml"
NAMESPACE="myserver"
SCRIPT_DIR="k8s/scripts"

build(){
  docker build -t vinhphuctadang/key-value-server .
  # docker save hello-kube:latest | (eval $(minikube docker-env) && docker load) # save to local for minikube to pull, since 'minikube' use different docker env
  docker push vinhphuctadang/key-value-server:latest
}

migrate(){ # migrate from docker --> minikube
  img=$2
  echo "Moving ${img} from docker to minikube, without pushing to dockerhub"
  docker save ${img} | (eval $(minikube docker-env) && docker load)
}

serverInit(){
  kubectl apply -f ${SERVER} -n $NAMESPACE
  kubectl apply -f ${INGRESS} -n $NAMESPACE
}

bootUp(){
  echo "Create server namespace called '${NAMESPACE}'"
  kubectl create namespace $NAMESPACE
  kubectl apply -f ${MUTAL_VOLUME} -n $NAMESPACE # create a 'mutal' volume, will be referred by configservers, shards and mongo routers
  kubectl apply -f ${MONGO_CFG_SERVER} -n $NAMESPACE # start mongo config servers and their service
  kubectl apply -f ${MONGO_SHARD} -n $NAMESPACE # start 2 shards with persistent volumes
  kubectl apply -f ${MONGO_ROUTER} -n $NAMESPACE # start mongo router for exposing mongodb to our node app (app written in nodejs, in /app)
}

waitBootComplete(){
  while [[ $(kubectl get pod -n myserver -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') == *"False"* ]]; do
    echo "Sleep 1 second and while waiting for components to complete booting up"
    sleep 1
  done
}

copyScripts(){
  echo "Copying mongo init scripts to config-volume volume (via POD mongod-configdb-0)"
  kubectl cp ${SCRIPT_DIR} mongod-configdb-0:/config -n $NAMESPACE
}

mongoInit(){
  echo "First copy k8s/scripts to created config-volume"
  copyScripts
  echo "Then waiting for 30s for mongo components to complete boot up"
  sleep 30

  kubectl exec pod/mongod-configdb-0 -n $NAMESPACE -- sh -c "mongo --port 27017 < /config/scripts/init-configserver.js" # init on one replica only
  # afterward
  # use for loop instead
  kubectl exec pod/mongo-shard0-0 -n $NAMESPACE -- sh -c "mongo --port 27017 < /config/scripts/init-shard0.js"
  kubectl exec pod/mongo-shard1-0 -n $NAMESPACE -- sh -c "mongo --port 27017 < /config/scripts/init-shard1.js"


  kubectl exec $(kubectl get pod -l "name=mongos" -n $NAMESPACE -o name) \
    -n $NAMESPACE -- sh -c "mongo --port 27017 < /config/scripts/init-router.js"

  kubectl exec $(kubectl get pod -l "name=mongos" -n $NAMESPACE -o name) \
    -n $NAMESPACE -- sh -c "mongo --port 27017 < /config/scripts/init-collection.js"
  echo "In case this script failed, mostly because components are not booting up completely, you should run ./cmd.sh mongoInit again"
}

waitAndInit(){
  waitBootComplete
  mongoInit
  serverInit
}

start(){
  bootUp
  waitAndInit
}

stop(){
  kubectl delete -f ${MONGO_CFG_SERVER} -n $NAMESPACE
  kubectl delete -f ${MONGO_SHARD} -n $NAMESPACE
  kubectl delete -f ${MONGO_ROUTER} -n $NAMESPACE
  kubectl delete -f ${SERVER} -n $NAMESPACE
  kubectl delete -f ${INGRESS} -n $NAMESPACE
  kubectl delete -f ${MUTAL_VOLUME} -n $NAMESPACE

  kubectl delete namespace $NAMESPACE
}

clean(){
	kubectl delete all --all -n $NAMESPACE
}

CMD=$1

case $CMD in
  "build")
    echo "Dockerizing server..."
    build
    ;;

  "start")
    echo "Starting components..."
    start
    ;;

  "stop")
    echo "Stoping components..."
    stop
    ;;

  "clean")
    echo "Cleaning up server named '${NAMESPACE}'"
    clean
    ;;

  "waitAndInit") # This will wait for components to completely boot up and automatically call mongoInit, that's it. Should only use this command for debugging purpose
    waitAndInit
    ;;

  "mongoInit")
    echo "Initializing mongo..."
    mongoInit
    ;;
  "copyScripts")
    copyScripts
    ;;

  "migrate")
    migrate $@
    ;;

  *)
    echo "unknown command"
    ;;
esac
