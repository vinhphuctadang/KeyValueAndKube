rs.initiate(
   {
      _id: "shard1",
      version: 1,
      members: [
         { _id: 0, host : "mongo-shard1-0.shard1-service.myserver.svc.cluster.local:27017" },
      ]
   }
)
