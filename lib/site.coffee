# Modify website files

fs = require 'fs'
yaml = require 'yamljs'
matter = require 'gray-matter'

util = require './util'

engines =
  yaml:
    parse: yaml.parse.bind(yaml)
    stringify: yaml.dump.bind(yaml)

  newInfo: (infoStr) ->
    info =
      layout: 'greyhound'
      date: util.nowDate()
      category: 'available'
    infoStr.toLowerCase().split(',').map (i) ->
      [key, val] = i.split('=', 2).map (j) -> j.trim()
      info[key] =
        switch key
          when 'dob','doa','dod'
            util.thisDate(val)
          when 'cats','pending','permafoster'
            val is 'yes'
          else
            val
    info.title = util.capitalize info.name
    return info

  newGreyhound: (path, greyhound) ->
    num = 0
    fileName = greyhound
    while fs.existsSync "#{path}/_greyhounds/#{fileName}.md"
      num += 1
      fileName = "#{greyhound}#{num}"
    console.log "New greyhound #{fileName}"
    return fileName

  loadGreyhound: (path, greyhound, callback) ->
    file = "#{path}/_greyhounds/#{greyhound}.md"
    fs.readFile file, 'utf8', (err, data) ->
      if err
        return callback null, null
      console.log "Loaded #{greyhound}"
      info = matter data, engines: engines
      callback info.data, info.content

  dumpGreyhound: (path, greyhound, info, bio, callback) ->
    file = "#{path}/_greyhounds/#{greyhound}.md"
    try
      data = matter.stringify bio, info, engines: engines
    catch err
      return callback err
    console.log "Dump #{greyhound}"
    fs.writeFile file, data, (err) ->
      callback err
