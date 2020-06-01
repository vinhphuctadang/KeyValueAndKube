rs.initiate(
   {
      _id: "shard0",
      version: 1,
      members: [
         { _id: 0, host : "mongo-shard0-0.shard0-service.myserver.svc.cluster.local:27017" }
      ]
   }
)
