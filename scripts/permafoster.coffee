# Description:
#   Label a greyhound as a permanent foster
#
# Commands:
#   hubot permafoster <greyhound> - Labels a greyhound as a permanent foster
#
# Author:
#   Zach Whaley (zachwhaley) <zachbwhaley@gmail.com>

capitalize = require 'capitalize'

git = require '../lib/git'
site = require '../lib/site'

permafoster = (greyhound, callback) ->
  site.loadGreyhound greyhound, (info, bio) ->
    if not info?
      return callback "Sorry, couldn't find #{greyhound} 😕"

    if info.category is 'deceased'
      return callback "#{capitalize.words(greyhound)} has crossed the Rainbow Bridge 😢"
    if info.category is 'adopted'
      return callback "#{capitalize.words(greyhound)} has already been adopted 😝"
    if info.permafoster is yes
      return callback "#{capitalize.words(greyhound)} is already a permanent foster 🤕"

    info.permafoster = yes
    site.dumpGreyhound greyhound, info, bio, callback

module.exports = (robot) ->
  robot.respond /permafoster (.*)/i, (res) ->
    greyhound = res.match[1]?.toLowerCase()
    gitOpts =
      message: "#{capitalize.words(greyhound)} Permanent Foster 🤕"
      branch: "permafoster-#{greyhound}"
      user:
        name: res.message.user?.real_name
        email: res.message.user?.profile?.email

    res.reply "Labeling #{capitalize.words(greyhound)} as a Permanent Foster 🤕\n" +
              "Hang on a sec..."

    git.update permafoster, greyhound, gitOpts, (update) ->
      res.reply update
