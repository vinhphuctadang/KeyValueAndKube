sh.addShard("/:27018")
sh.addShard("shard01/shard01b:27018")

sh.addShard("shard02/shard02a:27019")
sh.addShard("shard02/shard02b:27019")

sh.enableSharding('test')
