# Description:
#   Label a greyhound as cat safe or not
#
# Dependencies:
#   "github-api": "3.0.0"
#   "nodegit": "0.18.3"
#
# Commands:
#   hubot cats <yes|no> <greyhound> - Label a greyhound as cat safe or not
#
# Author:
#   Zach Whaley (zachwhaley) <zachbwhaley@gmail.com>

fs = require 'fs'
git = require './git'

catsafe = (repo, greyhound, safe, callback) ->
  file = "#{repo.workdir()}/_data/greyhounds.yml"
  fs.readFile file, 'utf8', (err, data) ->
    return callback err if err

    m = data.match ///^#{greyhound}:$///m
    if m is null
      return callback "Sorry, couldn't find #{greyhound} 😕"

    err = null
