sh.enableSharding('test')
use test
db.KeyValue.drop() // drop collection for creation safety
db.createCollection('KeyValue')
db.KeyValue.createIndex({key:1}, {unique: true})
sh.shardCollection('test.KeyValue', {key: 'hashed'}, false, {numInitialChunks: 2})
db.KeyValue.getShardDistribution()
