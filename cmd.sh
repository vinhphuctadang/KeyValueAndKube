
# CONSTANTS
MONGO_CFG_SERVER="k8s/dev/mongo/configserver.yaml" # config for mongo config server
MONGO_SHARD="k8s/dev/mongo/shard.yaml" # config for mongo shards
MONGO_ROUTER="k8s/dev/mongo/router.yaml"

MUTAL_VOLUME="k8s/dev/config-volume.yaml"
SERVER="k8s/dev/server.yaml"
INGRESS="k8s/dev/ingress.yaml"
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
  minikube addons enable ingress # enable ingress in order to make server externally visible
  kubectl apply -f ${SERVER}
  kubectl apply -f ${INGRESS}
  echo "Sleep for server booting up"
  sleep 5
  echo "======= Ingress information ======="
  kubectl get ingress
}

bootUp(){
  kubectl apply -f ${MUTAL_VOLUME}
  kubectl apply -f ${MONGO_CFG_SERVER}
  kubectl apply -f ${MONGO_SHARD}
  kubectl apply -f ${MONGO_ROUTER}
}

waitBootComplete(){
  while [[ $(kubectl get pod -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') == *"False"* ]]; do
    echo "Sleep 1 second and while waiting for components to complete booting up"
    sleep 1
  done
}

copyScripts(){
  echo "Copying mongo init scripts to config-volume volume (via POD mongod-configdb-0)"
  kubectl cp ${SCRIPT_DIR} mongod-configdb-0:/config
}

mongoInit(){

  echo "Waiting for 30s for mongo components to complete boot up"
  sleep 30
  echo "Next copy k8s/scripts to created config-volume"
  copyScripts

  kubectl exec pod/mongod-configdb-0 -- sh -c "mongo --port 27017 < /config/scripts/init-configserver.js" # init on one replica only
  # afterward
  # use for loop instead
  kubectl exec pod/mongo-shard0-0 -- sh -c "mongo --port 27017 < /config/scripts/init-shard0.js"
  kubectl exec pod/mongo-shard1-0 -- sh -c "mongo --port 27017 < /config/scripts/init-shard1.js"


  kubectl exec $(kubectl get pod -l "name=mongos" -o name) \
  -- sh -c "mongo --port 27017 < /config/scripts/init-router.js"

  kubectl exec $(kubectl get pod -l "name=mongos" -o name) \
  -- sh -c "mongo --port 27017 < /config/scripts/init-collection.js"

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
  kubectl delete -f ${MONGO_CFG_SERVER}
  kubectl delete -f ${MONGO_SHARD}
  kubectl delete -f ${MONGO_ROUTER}
  kubectl delete -f ${SERVER}
  kubectl delete -f ${INGRESS}
  kubectl delete -f ${MUTAL_VOLUME}
  kubectl delete namespace
}

clean(){
	kubectl delete all --all
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
    echo "Cleaning up server'"
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

  "ingress")
    kubectl get ingress
    ;;

  *)
    echo "unknown command"
    ;;
esac
