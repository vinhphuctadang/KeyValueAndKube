const db = require('./db.js')
const express = require('express')
const router = express.Router()


async function set(key, value){
  await db.KeyValue.findOneAndUpdate({key: key}, {$set: {value: value}}, {new: true, upsert: true})
  return true
}

async function get(key){
  let result = await db.KeyValue.findOne({key: key})
  if (!result)
    throw `${key} not found`
  return result.value
}

router.get('/valueof/:key', async(req, res)=>{
	let key = req.params.key
  // console.log('Param',req.param)
	console.log('Get',key)
  let result
  try {
    result = await get(key)
	  res.send(result)
  } catch(e) {
    res.send("Not found")
  }
})

router.post('/', async(req, res)=>{
	let key = req.body.key
	let value = req.body.value
	await set(key, value)
	res.send('Set value of key "' + key + '" to "' + value + '". Back to <a href="/set.html">set page</a>');
})

module.exports = router
