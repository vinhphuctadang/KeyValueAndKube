sh.addShard("shard0/mongo-shard0-0.shard0-service.myserver.svc.cluster.local:27017")
sh.addShard("shard1/mongo-shard0-1.shard0-service.myserver.svc.cluster.local:27017")

sh.addShard("shard1/mongo-shard1-0.shard1-service.myserver.svc.cluster.local:27017")
sh.addShard("shard1/mongo-shard1-1.shard1-service.myserver.svc.cluster.local:27017")

sh.enableSharding('test')
