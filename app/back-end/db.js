const mongoose = require('mongoose')

mongoose.connect('mongodb://localhost:27017/test', {useNewUrlParser: true});
var schema = new mongoose.Schema({ key: 'string', value: 'string' });
var KeyValue = mongoose.model('KeyValue', schema);

module.exports = {
  KeyValue : KeyValue,
}
