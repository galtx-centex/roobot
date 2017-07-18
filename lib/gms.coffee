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
      url: 'https://www.madhome.net/gmstest/gms_dogintjsonservice.php'
      body: payload
      json: true
    request.post opts, (err, res, body) ->
      console.log "ERR: #{err}"
      console.log "CODE: #{res.statusCode}"
      console.log "MSG: #{res.statusMessage}"
      console.log "BODY: #{body}"
      console.log "STATUS: #{body.status}"
      if err
        callback "GMS Failed to Update, #{err}"
      if res.statusCode isnt 200
        callback "GMS Failed to Update, #{res.statusCode}: #{res.statusMessage}"
      # TODO Find out what the actual success status is
      if body.status isnt "SUCCESS"
        callback "GMS Failed to Update, #{body.status_message}"
