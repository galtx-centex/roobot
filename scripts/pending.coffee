# Description:
#   Label a greyhound as pending adoption
#
# Commands:
#   hubot pending <greyhound> - Labels a greyhound as pending adoption
#
# Author:
#   Zach Whaley (zachwhaley) <zachbwhaley@gmail.com>

capitalize = require 'capitalize'

git = require '../lib/git'
site = require '../lib/site'

pending = (greyhound, callback) ->
  site.loadGreyhound greyhound, (info, bio) ->
    if not info?
      return callback "Sorry, couldn't find #{greyhound} 😕"

    if info.category is 'deceased'
      return callback "#{capitalize(greyhound)} has crossed the Rainbow Bridge 😢"
    if info.category is 'adopted'
      return callback "#{capitalize(greyhound)} has already been adopted 😝"
    if info.pending is yes
      return callback "#{capitalize(greyhound)} is already pending adoption 😝"

    info.pending = yes
    site.dumpGreyhound greyhound, info, bio, callback

module.exports = (robot) ->
  robot.respond /pending (.*)/i, (res) ->
    greyhound = res.match[1]?.toLowerCase()
    gitOpts =
      message: "#{capitalize(greyhound)} Pending Adoption! 🎉"
      branch: "pending-#{greyhound}"
      user:
        name: res.message.user?.real_name
        email: res.message.user?.profile?.email

    res.reply "Labeling #{capitalize(greyhound)} as Pending Adoption! 🎉\n" +
              "Hang on a sec..."

    git.update pending, greyhound, gitOpts, (update) ->
      res.reply update
