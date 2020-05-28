build(){
  docker build -t key-value-server .
  # docker save hello-kube:latest | (eval $(minikube docker-env) && docker load) # save to local for minikube to pull, since 'minikube' use different docker env
  docker push vinhphuctadang/key-value-server:latest
}

start(){
  kubectl create namespace myserver
  kubectl apply -f deploy.yaml -n myserver
  kubectl apply -f ingress.yaml -n myserver
}

stop(){
  kubectl delete -f deploy.yaml -n myserver
  kubectl delete -f ingress.yaml -n myserver
  kubectl delete namespace myserver
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

  *)
    echo "unknown command"
    ;;
esac
