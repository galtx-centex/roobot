# Utility functions
fs = require 'fs'
url = require 'url'
https = require 'https'

module.exports =
  nowDate: () ->
    now = new Date()
    return new Date Date.UTC(now.getFullYear(), now.getMonth(), now.getDate())

  download: (src, dest, callback) ->
    console.log "Download #{src}"
    file = fs.createWriteStream dest
    opts = url.parse src
    opts.headers =
      Authorization: "Bearer #{process.env.HUBOT_SLACK_TOKEN}"
    https.get opts, (resp) ->
      resp.pipe file
      file.on 'finish', ->
        console.log "Download finished"
        # close() is async, call callback after close completes.
        file.close callback
    # Handle errors
    .on 'error', (err) ->
      # Delete the file async. (But we don't check the result)
      fs.unlink dest
      callback err.message

  sanitize: (name) ->
    return name.replace /\s+/g, '-'
