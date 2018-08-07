# Description:
#   Move an deceased greyhound to the Rainbow Bridge page
#
# Commands:
#   hubot goodbye <greyhound> [yyyy-mm-dd] - Moves a deceased greyhound to the Rainbow Bridge page
#
# Author:
#   Zach Whaley (zachwhaley) <zachbwhaley@gmail.com>

git = require '../lib/git'
site = require '../lib/site'
util = require '../lib/util'

goodbye = (greyhound, name, dod, callback) ->
  site.loadGreyhound greyhound, (info, bio) ->
    if not info?
      return callback "Sorry, couldn't find #{greyhound} 😕"

    if info.category is 'deceased'
      return callback "#{name} has already crossed the Rainbow Bridge 😢"

    info.category = 'deceased'
    info.dod = new Date(dod) if dod?
    site.dumpGreyhound greyhound, info, bio, callback

module.exports = (robot) ->
  robot.respond /goodbye (.+?)\s*(\d{4}-\d{1,2}-\d{1,2})?$/i, (res) ->
    greyhound = util.slugify res.match[1]
    name = util.capitalize res.match[1]
    dod = res.match[2]
    gitOpts =
      message: "#{name} crossed the Rainbow Bridge 😢"
      branch: "goodbye-#{greyhound}"
      user:
        name: res.message.user?.real_name
        email: res.message.user?.email_address

    res.reply "Moving #{name} to the Rainbow Bridge 😢\n" +
              "Hang on a sec..."

    git.update goodbye, greyhound, name, dod, gitOpts, (err) ->
      unless err?
        res.reply "#{name} moved to the Rainbow Bridge 😢"
      else
        res.reply err
