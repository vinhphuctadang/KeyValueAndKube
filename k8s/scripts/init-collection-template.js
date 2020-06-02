sh.enableSharding('test')
use test

db.createCollection('<Collection name>')
db.<Collection name>.createIndex({ <key>: 1}, {unique: true})
sh.shardCollection('test.<Collection name>', {<key>: 'hashed/1'}, false, {numInitialChunks: <number of chunks>})
db.<Collection name>.getShardDistribution()
