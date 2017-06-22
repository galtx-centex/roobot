# Modify website files

fs = require 'fs'
path = require 'path'
yaml = require 'yamljs'
matter = require 'gray-matter'

sitePath = path.join __dirname, 'gpa-centex.org'

module.exports =
  loadGreyhound: (greyhound, callback) ->
    file = "#{sitePath}/_greyhounds/#{greyhound}.md"
    fs.readFile file, 'utf8', (err, data) ->
      if err
        return callback null, null
      info = matter data, parser: yaml.parse
      callback info.data, info.content

  dumpGreyhound: (greyhound, info, bio, callback) ->
    file = "#{sitePath}/_greyhounds/#{greyhound}.md"
    data = matter.stringify bio, info, dumper: yaml.dump
    fs.writeFile file, data, (err) ->
      callback err
