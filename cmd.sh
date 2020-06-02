'''
CONSTANTS
'''
MONGO_CFG_SERVER="k8s/dev/mongo/configserver.yaml"
MONGO_SHARD="k8s/dev/mongo/shard.yaml"
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

start(){
  echo "Create server namespace called '${NAMESPACE}'"
  kubectl create namespace $NAMESPACE
  kubectl apply -f ${MUTAL_VOLUME} -n $NAMESPACE # create a 'mutal' volume, will be referred by configservers, shards and mongo routers
  kubectl apply -f ${MONGO_CFG_SERVER} -n $NAMESPACE # start mongo config servers and their service
  kubectl apply -f ${MONGO_SHARD} -n $NAMESPACE # start 2 shards with persistent volumes
  kubectl apply -f ${MONGO_ROUTER} -n $NAMESPACE # start mongo router for exposing mongodb to our node app (app written in nodejs, in /app)
  kubectl apply -f ${SERVER} -n $NAMESPACE
  kubectl apply -f ${INGRESS} -n $NAMESPACE

  kubectl cp ${SCRIPT_DIR} pod/mongod-configdb-0:/config -n $NAMESPACE
  # afterward
  # use for loop instead
  kubectl exec pod/mongo-shard0-0 -n $NAMESPACE -- sh -c "mongo --port 27017 < /config/init-shard0.js"
  kubectl exec pod/mongo-shard1-0 -n $NAMESPACE -- sh -c "mongo --port 27017 < /config/init-shard1.js"
  kubectl exec pod/mongod-configdb-0 -n $NAMESPACE -- sh -c "mongo --port 27017 < /config/init-configserver.js"
  kubectl exec pod/mongod-configdb-1 -n $NAMESPACE -- sh -c "mongo --port 27017 < /config/init-configserver.js"

  kubectl exec $(kubectl get pod -l "name=mongos" -o name) \
    -n $NAMESPACE -- sh -c "mongo --port 27017 < /config/init-collection.js"
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

  "migrate")
    migrate
    ;;


  *)
    echo "unknown command"
    ;;
esac
