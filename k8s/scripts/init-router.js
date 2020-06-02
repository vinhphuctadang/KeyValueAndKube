sh.addShard("shard0/mongo-shard0-0.shard0-service.myserver.svc.cluster.local:27017")
sh.addShard("shard1/mongo-shard1-0.shard1-service.myserver.svc.cluster.local:27017")
sh.enableSharding('test')
