const express = require('express')
const parser = require('body-parser')
const route = require('./back-end/routes')
const app = express()
const PORT = process.env.PORT || 8000

app.use(parser.json())
app.use(parser.urlencoded({extended: true}))
app.use(express.static('front-end'))
app.use('/', route)

app.listen(PORT, async =>{
	console.log('Listening on port', PORT)
})
