# Description:
#   Label a greyhound as a permanent foster
#
# Commands:
#   hubot permafoster <greyhound> - Labels a greyhound as a permanent foster
#
# Author:
#   Zach Whaley (zachwhaley) <zachbwhaley@gmail.com>

git = require '../lib/git'
site = require '../lib/site'
util = require '../lib/util'

permafoster = (greyhound, callback) ->
  site.loadGreyhound greyhound, (info, bio) ->
    if not info?
      return callback "Sorry, couldn't find #{greyhound} 😕"

    if info.category is 'deceased'
      return callback "#{util.display(greyhound)} has crossed the Rainbow Bridge 😢"
    if info.category is 'adopted'
      return callback "#{util.display(greyhound)} has already been adopted 😝"
    if info.permafoster is yes
      return callback "#{util.display(greyhound)} is already a permanent foster 😞"

    info.permafoster = yes
    site.dumpGreyhound greyhound, info, bio, callback

module.exports = (robot) ->
  robot.respond /permafoster (.*)/i, (res) ->
    greyhound = util.sanitize res.match[1]
    gitOpts =
      message: "#{util.display(greyhound)} Permanent Foster 💜"
      branch: "permafoster-#{greyhound}"
      user:
        name: res.message.user?.real_name
        email: res.message.user?.profile?.email

    res.reply "Labeling #{util.display(greyhound)} as a Permanent Foster 💜\n" +
              "Hang on a sec..."

    git.update permafoster, greyhound, gitOpts, (update) ->
      res.reply update
