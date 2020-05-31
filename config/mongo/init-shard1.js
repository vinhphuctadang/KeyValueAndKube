rs.initiate(
   {
      _id: "shard1",
      version: 1,
      members: [
         { _id: 0, host : "mongo-shard0-0.shard1-service.myserver.svc.cluster.local:27017" },
         { _id: 1, host : "mongo-shard0-1.shard1-service.myserver.svc.cluster.local:27017" },
      ]
   }
)
