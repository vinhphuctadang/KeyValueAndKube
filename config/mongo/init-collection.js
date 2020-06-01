sh.enableSharding('test')
use test
db.createCollection('KeyValue')
db.KeyValue.createIndex({key:1}, {unique: true})
sh.shardCollection('test.KeyValue', {key: 'hashed'}, false, {numInitialChunks: 2})
db.KeyValue.getShardDistribution()
