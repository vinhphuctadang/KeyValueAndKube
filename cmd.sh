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
  kubectl create namespace myserver
  kubectl apply -f ${MONGO_CFG_SERVER} -n myserver # start mongo config servers and their service
  kubectl apply -f ${MONGO_SHARD} -n myserver # start 2 shards with persistent volumes
  kubectl apply -f ${MONGO_ROUTER} -n myserver # start mongo router for exposing mongodb to our node app (app written in nodejs, in /app)
  kubectl apply -f ${SERVER} -n myserver
  kubectl apply -f ${INGRESS} -n myserver
  kubectl apply -f ${MUTAL_VOLUME} -n myserver
}

stop(){
  kubectl delete -f ${MONGO_CFG_SERVER} -n myserver
  kubectl delete -f ${MONGO_SHARD} -n myserver
  kubectl delete -f ${MONGO_ROUTER} -n myserver
  kubectl delete -f ${SERVER} -n myserver
  kubectl delete -f ${INGRESS} -n myserver

  kubectl delete namespace myserver
}

clean(){
	kubectl delete all --all -n myserver
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
    echo "Cleaning up server named 'myserver'"
    clean
    ;;

  "migrate")
    migrate
    ;;


  *)
    echo "unknown command"
    ;;
esac
