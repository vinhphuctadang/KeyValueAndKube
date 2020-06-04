
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

migrate(){ # migrate from docker --> minikube, use this in case you have docker images already and want to copy it to 'minikube docker'
  img=$2
  echo "Moving ${img} from docker to minikube, without pushing to dockerhub"
  docker save ${img} | (eval $(minikube docker-env) && docker load)
}

copyScripts(){
  echo "Copying mongo init scripts to config-volume volume (via POD mongod-configdb-0) ..."
  kubectl cp ${SCRIPT_DIR} mongod-configdb-0:/config
}

mongoInit(){
  kubectl apply -f ${MUTAL_VOLUME}  # create a 'mutal' volume, will be referred by configservers, shards and mongo routers
  kubectl apply -f ${MONGO_CFG_SERVER}  # start mongo config servers and their service
  kubectl apply -f ${MONGO_SHARD}  # start 2 shards with persistent volumes
  kubectl apply -f ${MONGO_ROUTER}  # start mongo router for exposing mongodb to our node app (app written in nodejs, in /app)

  while [[ $(kubectl get pod -n myserver -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') == *"False"* ]]; do
    echo "Waiting for mongo components' readiness"
    sleep 1
  done

  sleep 30
  echo "Next copy k8s/scripts to create config-volume"
  copyScripts

  echo "After that, run configs"
  kubectl exec pod/mongod-configdb-0  -- sh -c "mongo --port 27017 < /config/scripts/init-configserver.js" # init on one replica only
  kubectl exec pod/mongo-shard0-0  -- sh -c "mongo --port 27017 < /config/scripts/init-shard0.js"
  kubectl exec pod/mongo-shard1-0  -- sh -c "mongo --port 27017 < /config/scripts/init-shard1.js"

  kubectl exec $(kubectl get pod -l "name=mongos"  -o name) \
     -- sh -c "mongo --port 27017 < /config/scripts/init-router.js"

  kubectl exec $(kubectl get pod -l "name=mongos"  -o name) \
     -- sh -c "mongo --port 27017 < /config/scripts/init-collection.js"

  echo "In case this script failed, mostly because mongo components are not booting up completely, you should run './cmd.sh mongoInit' again"
}

serverInit(){
  minikube addons enable ingress # enable ingress in order to make server externally visible
  kubectl apply -f ${SERVER}
  kubectl apply -f ${INGRESS}
  echo "Sleep to wait for server to complete boot itself up"
  sleep 5
  echo "======= Ingress information ======="
  kubectl get ingress
}

# waitComponentsReadiness(){
#   while [[ $(kubectl get pod -n myserver -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') == *"False"* ]]; do
#     echo "Sleep 1 second while waiting for components to be ready"
#     sleep 1
#   done
# }

start(){
  mongoInit
  serverInit
}

stop(){
  kubectl delete -f ${MONGO_CFG_SERVER}
  kubectl delete -f ${MONGO_SHARD}
  kubectl delete -f ${MONGO_ROUTER}
  kubectl delete -f ${SERVER}
  kubectl delete -f ${INGRESS}
  kubectl delete -f ${MUTAL_VOLUME}
}

clean(){
	kubectl delete all --all
}

CMD=$1

case $CMD in
  "build") # build the current server to docker
    echo "Dockerizing server..."
    build
    ;;

  "start") # Run this one to start components
    echo "Starting components..."
    start
    ;;

  "stop") # Run this one to stop components
    echo "Stoping components..."
    stop
    ;;


############ For debugging purpose ##############
  "clean") # DO NOT USE THIS IN PRODUCTION.N.N
    echo "Cleaning up server"
    clean
    ;;

  "mongoInit")
    echo "Initializing mongo..."
    mongoInit
    ;;

  "copyScripts") # To copy into config-volume via POD mongod-configdb-0, only for debugging purpose
    copyScripts
    ;;

  "migrate")
    migrate $@
    ;;

  "ingress")
    kubectl get ingress
    ;;
  "restartServer") # in case server failed its initialization phase (mostly due to mongo errors), we could manually restart the server
    echo 'Restarting our server'
    kubectl rollout restart deployment/key-value-deployment
    
    ;;

#####################################################
  *)
    echo "unknown command"
    ;;
esac
