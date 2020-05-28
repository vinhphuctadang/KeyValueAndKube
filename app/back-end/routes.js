const db = require('./db.js')
const express = require('express')
const router = express.Router()


async function set(key, value){
  let result = await db.KeyValue.findOneAndUpdate({key: key}, {$set: {value: value}}, {upsert: true})
  return true
}

async function get(key){
  let result = await db.KeyValue.findOne({key: key})
  if (!result)
    throw `${key} not found`
  return result.value
}

app.get('/:key', async(req, res)=>{
	let key = req.param.key
	console.log('Get ' + key)
  let result
  try {
    result = await get(key)
	  res.send(result)
  } catch() {
    res.send("Not found")
  }
})

app.post('/', async(req, res)=>{
	let key = req.body.key
	let value = req.body.value
	await set(key, value)
	res.send('Set value of key "' + key + '" to "' + value + '"');
})

module.exports = router
