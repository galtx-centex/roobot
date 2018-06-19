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

permafoster = (greyhound, name, callback) ->
  site.loadGreyhound greyhound, (info, bio) ->
    if not info?
      return callback "Sorry, couldn't find #{greyhound} 😕"

    if info.category is 'deceased'
      return callback "#{name} has crossed the Rainbow Bridge 😢"
    if info.category is 'adopted'
      return callback "#{name} has already been adopted 😝"
    if info.permafoster is yes
      return callback "#{name} is already a permanent foster 😞"

    info.permafoster = yes
    site.dumpGreyhound greyhound, info, bio, callback

module.exports = (robot) ->
  robot.respond /permafoster (.*)/i, (res) ->
    greyhound = util.slugify res.match[1]
    name = util.capitalize res.match[1]
    gitOpts =
      message: "#{name} Permanent Foster 💜"
      branch: "permafoster-#{greyhound}"
      user:
        name: res.message.user?.real_name
        email: res.message.user?.profile?.email

    res.reply "Labeling #{name} as a Permanent Foster 💜\n" +
              "Hang on a sec..."

    git.update permafoster, greyhound, name, gitOpts, (update) ->
      res.reply update
