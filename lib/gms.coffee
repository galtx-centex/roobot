# GMS Integration

request = require 'request'

module.exports =
  update: (action, greyhound, data, callback) ->
    payload =
      token: process.env.GMS_TOKEN
      action: action
      dogname: greyhound
      data: data
    opts =
      # TODO Replace with production link
      url: 'https://www.madhome.net/gmstest/gms_dogintjsonservice.php'
      body: payload
      json: true
    request.post opts, (err, res, body) ->
      if err
        callback "GMS Failed to Update, #{err}"
      if res.statusCode isnt 200
        callback "GMS Failed to Update, #{res.statusCode}: #{res.statusMessage}"

      if body.status is 0
        callback body.status_message
      else
        callback "GMS Failed to Update, #{body.status_message}"
