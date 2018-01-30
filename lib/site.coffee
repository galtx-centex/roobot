# Modify website files

fs = require 'fs'
path = require 'path'
yaml = require 'yamljs'
matter = require 'gray-matter'

engines =
  yaml:
    parse: yaml.parse.bind(yaml)
    stringify: yaml.dump.bind(yaml)

self = module.exports =
  sitePath: path.join __dirname, 'gpa-centex.org'

  newInfo: (greyhound, infoStr) ->
    info =
      layout: 'greyhound'
      title: capitalize greyhound
      date: util.nowDate()
      category: 'available'
    infoStr.toLowerCase().split(',').map (i) ->
      [key, val] = i.split('=', 2).map (j) -> j.trim()
      info[key] =
        switch key
          when 'dob','doa','dod'
            new Date val
          when 'cats','pending','permafoster'
            val is 'yes'
          else
            val
    return info

  newGreyhound: (greyhound) ->
    num = 0
    file = greyhound
    while fs.existsSync "#{self.sitePath}/_greyhounds/#{file}.md"
      num += 1
      file = "#{greyhound}#{num}"
    return file

  loadGreyhound: (greyhound, callback) ->
    file = "#{self.sitePath}/_greyhounds/#{greyhound}.md"
    fs.readFile file, 'utf8', (err, data) ->
      if err
        return callback null, null
      info = matter data, engines: engines
      callback info.data, info.content

  dumpGreyhound: (greyhound, info, bio, callback) ->
    file = "#{self.sitePath}/_greyhounds/#{greyhound}.md"
    data = matter.stringify bio, info, engines: engines
    fs.writeFile file, data, (err) ->
      callback err
