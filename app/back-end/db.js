const mongoose = require('mongoose')

mongoose.connect('mongodb://localhost:27017/test', {useNewUrlParser: true, useUnifiedTopology: true, useFindAndModify: false}); // useFindAndModify disable useFindOneAndModify to make following calls 'compatible' with old versions
var schema = new mongoose.Schema({ key: 'string', value: 'string' });
var KeyValue = mongoose.model('KeyValue', schema);

module.exports = {
  KeyValue : KeyValue,
}
