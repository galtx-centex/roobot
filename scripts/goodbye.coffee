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

goodbye = (greyhound, dod, callback) ->
  site.loadGreyhound greyhound, (info, bio) ->
    if not info?
      return callback "Sorry, couldn't find #{greyhound} 😕"

    if info.category is 'deceased'
      return callback "#{util.display(greyhound)} has already crossed the Rainbow Bridge 😢"

    info.category = 'deceased'
    info.dod = new Date(dod) if dod?
    site.dumpGreyhound greyhound, info, bio, callback

module.exports = (robot) ->
  robot.respond /goodbye (.+?)\s*(\d{4}-\d{1,2}-\d{1,2})?$/i, (res) ->
    greyhound = util.sanitize res.match[1]
    dod = res.match[2]
    gitOpts =
      message: "#{util.display(greyhound)} crossed the Rainbow Bridge 😢"
      branch: "goodbye-#{greyhound}"
      user:
        name: res.message.user?.real_name
        email: res.message.user?.profile?.email

    res.reply "Moving #{util.display(greyhound)} to the Rainbow Bridge 😢\n" +
              "Hang on a sec..."

    git.update goodbye, greyhound, dod, gitOpts, (update) ->
      res.reply update
