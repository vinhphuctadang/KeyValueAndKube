sh.addShard("mongo-shard0-0.shard0-service.myserver.svc.cluster.local:27017")
sh.addShard("mongo-shard0-0.shard1-service.myserver.svc.cluster.local:27017")
sh.enableSharding('test')
