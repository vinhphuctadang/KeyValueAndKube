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
  kubectl apply -f config/mongo/configserver.yaml -n myserver # start mongo config servers and their service
  kubectl apply -f config/mongo/shard.yaml -n myserver # start 2 shards with persistent volumes
  kubectl apply -f config/mongo/router.yaml -n myserver # start mongo router for exposing mongodb to our node app (app written in nodejs, in /app)
  kubectl apply -f config/server.yaml -n myserver
  kubectl apply -f config/ingress.yaml -n myserver

  # there is another way: create a volume where we could place config together, but not in the following implementation

  kubectl cp ./config/mongo/init-shard0.js myserver/mongo-shard0-0:/init.js # copy init file to servers
  kubectl cp ./config/mongo/init-shard1.js myserver/mongo-shard1-0:/init.js # copy init file to servers, copy to all of its replica

  kubectl cp ./config/mongo/init-configserver.js myserver/mongod-configdb-0:/init.js
  kubectl cp ./config/mongo/init-configserver.js myserver/mongod-configdb-1:/init.js

  kubectl exec -it pod/mongo-shard0-0 -n myserver -- sh -c "mongo --port 27017 < init.js"
  kubectl exec -it pod/mongo-shard1-0 -n myserver -- sh -c "mongo --port 27017 < init.js"
  kubectl exec -it pod/mongod-configdb-0 -n myserver -- sh -c "mongo --port 27017 < init.js"
  kubectl exec -it pod/mongod-configdb-1 -n myserver -- sh -c "mongo --port 27017 < init.js"
}

stop(){
  kubectl delete -f config/mongo/configserver.yaml -n myserver
  kubectl delete -f config/mongo/shard.yaml -n myserver
  kubectl delete -f config/mongo/router.yaml -n myserver

  kubectl delete -f config/server.yaml -n myserver
  kubectl delete -f config/ingress.yaml -n myserver
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
