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

pendingMessage = (pending) ->
  if pending
    "Pending Adoption! 🎉"
  else
    "Not Pending Adoption 😞"

pending = (greyhound, name, pending, callback) ->
  site.loadGreyhound greyhound, (info, bio) ->
    if not info?
      return callback "Sorry, couldn't find #{greyhound} 😕"

    if info.category is 'deceased'
      return callback "#{name} has crossed the Rainbow Bridge 😢"
    if info.category is 'adopted'
      return callback "#{name} has already been adopted 😝"
    if pending and info.pending is yes
      return callback "#{name} is already pending adoption 😝"
    if not pending and info.pending is no
      return callback "#{name} is already not pending adoption 😝"

    info.pending = pending
    site.dumpGreyhound greyhound, info, bio, callback

module.exports = (robot) ->
  robot.respond /pending (.+?)(\s(yes|no))?$/i, (res) ->
    greyhound = util.slugify res.match[1]
    name = util.capitalize res.match[1]
    pend = yes
    if res.match[3]?.toLowerCase() is 'no'
      pend = no

    gitOpts =
      message: "#{name} #{pendingMessage(pend)}"
      branch: "pending-#{greyhound}"
      user:
        name: res.message.user?.real_name
        email: res.message.user?.email_address

    res.reply "Labeling #{name} as #{pendingMessage(pend)}\n" +
              "Hang on a sec..."

    git.update pending, greyhound, name, pend, gitOpts, (err) ->
      unless err?
        res.reply "#{name} labeled as #{pendingMessage(pend)}"
      else
        res.reply err
