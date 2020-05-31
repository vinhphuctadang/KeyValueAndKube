const mongoose = require('mongoose')

// the line below results in 'wrong' connection for our deployment since 'localhost' is treated as 127.0.0.1, not a name which could be indexed by a DNS
// mongoose.connect('mongodb://localhost:27017/test', {useNewUrlParser: true, useUnifiedTopology: true, useFindAndModify: false}); // useFindAndModify disable useFindOneAndModify to make following calls 'compatible' with old versionsmongoose.connect('mongodb://localhost:27017/test', {useNewUrlParser: true, useUnifiedTopology: true, useFindAndModify: false}); // useFindAndModify disable useFindOneAndModify to make following calls 'compatible' with old versions
const MONGO_HOST = process.env.MONGO_HOST || 'localhost'

console.log('DB HOST:', MONGO_HOST)


mongoose.connect(`mongodb://${MONGO_HOST}:27017/test`, {useNewUrlParser: true, useUnifiedTopology: true, useFindAndModify: false}); // useFindAndModify disable useFindOneAndModify to make following calls 'compatible' with old versionsmongoose.connect('mongodb://localhost:27017/test', {useNewUrlParser: true, useUnifiedTopology: true, useFindAndModify: false}); // useFindAndModify disable useFindOneAndModify to make following calls 'compatible' with old versions
var schema = new mongoose.Schema({ key: 'string', value: 'string' });
var KeyValue = mongoose.model('KeyValue', schema);

module.exports = {
  KeyValue : KeyValue,
}
