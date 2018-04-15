# Description:
#   Label a greyhound as pending adoption
#
# Commands:
#   hubot pending <greyhound> (yes/no) - Labels a greyhound as pending adoption
#
# Author:
#   Zach Whaley (zachwhaley) <zachbwhaley@gmail.com>

git = require '../lib/git'
site = require '../lib/site'
util = require '../lib/util'

pendingBranch = (pending) ->
  if pending
    "pending"
  else
    "not-pending"

pendingMessage = (pending) ->
  if pending
    "Pending Adoption! 🎉"
  else
    "Not Pending Adoption 😞"

pending = (greyhound, pending, callback) ->
  site.loadGreyhound greyhound, (info, bio) ->
    if not info?
      return callback "Sorry, couldn't find #{greyhound} 😕"

    if info.category is 'deceased'
      return callback "#{util.display(greyhound)} has crossed the Rainbow Bridge 😢"
    if info.category is 'adopted'
      return callback "#{util.display(greyhound)} has already been adopted 😝"
    if pending and info.pending is yes
      return callback "#{util.display(greyhound)} is already pending adoption 😝"
    if not pending and info.pending is no
      return callback "#{util.display(greyhound)} is already not pending adoption 😝"

    info.pending = pending
    site.dumpGreyhound greyhound, info, bio, callback

module.exports = (robot) ->
  robot.respond /pending (.+?)\s*(yes|no)?$/i, (res) ->
    greyhound = util.sanitize res.match[1]
    if res.match[2]?
      pend = res.match[2].toLowerCase() is 'yes'
    else
      pend = yes

    gitOpts =
      message: "#{util.display(greyhound)} #{pendingMessage(pend)}"
      branch: "#{pendingBranch(pend)}-#{greyhound}"
      user:
        name: res.message.user?.real_name
        email: res.message.user?.profile?.email

    res.reply "Labeling #{util.display(greyhound)} as #{pendingMessage(pend)}\n" +
              "Hang on a sec..."

    git.add pending, greyhound, pend, gitOpts, (update) ->
      res.reply update
