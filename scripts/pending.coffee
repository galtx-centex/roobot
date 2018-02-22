# Description:
#   Label a greyhound as pending adoption
#
# Commands:
#   hubot pending <greyhound> (yes/no) - Labels a greyhound as pending adoption
#
# Author:
#   Zach Whaley (zachwhaley) <zachbwhaley@gmail.com>

capitalize = require 'capitalize'

git = require '../lib/git'
site = require '../lib/site'

pendingBranch = (pending) ->
  return if pending then "pending" else "not-pending"

pendingMessage = (pending) ->
  return if pending then "Pending Adoption! 🎉" else "Not Pending Adoption 🤷"

pending = (greyhound, pending, callback) ->
  site.loadGreyhound greyhound, (info, bio) ->
    if not info?
      return callback "Sorry, couldn't find #{greyhound} 😕"

    if info.category is 'deceased'
      return callback "#{capitalize.words(greyhound)} has crossed the Rainbow Bridge 😢"
    if info.category is 'adopted'
      return callback "#{capitalize.words(greyhound)} has already been adopted 😝"
    if pending and info.pending is yes
      return callback "#{capitalize.words(greyhound)} is already pending adoption 😝"
    if not pending and info.pending is no
      return callback "#{capitalize.words(greyhound)} is already not pending adoption 😝"

    info.pending = pending
    site.dumpGreyhound greyhound, info, bio, callback

module.exports = (robot) ->
  robot.respond /pending (\w+)\s?(\w+)?/i, (res) ->
    greyhound = res.match[1]?.toLowerCase()
    if res.match[2]?
      pend = if res.match[2].toLowerCase() is 'no' then no else yes
    else
      pend = yes

    gitOpts =
      message: "#{capitalize.words(greyhound)} #{pendingMessage(pend)}"
      branch: "#{pendingBranch(pend)}-#{greyhound}"
      user:
        name: res.message.user?.real_name
        email: res.message.user?.profile?.email

    res.reply "Labeling #{capitalize.words(greyhound)} as #{pendingMessage(pend)}\n" +
              "Hang on a sec..."

    git.update pending, greyhound, pend, gitOpts, (update) ->
      res.reply update
