rs.initiate(
   {
      _id: "configserver",
      configsvr: true,
      version: 1,
      members: [
         { _id: 0, host : "mongod-configdb-0.mongodb-configdb-service.default.svc.cluster.local:27017" },
         { _id: 1, host : "mongod-configdb-1.mongodb-configdb-service.default.svc.cluster.local:27017" }
      ]
   }
)
