# Description:
#   Move an adopted greyhound to the Happy Tails page
#
# Commands:
#   hubot adopt <greyhound> [yyyy-mm-dd] - Moves an adopted greyhound to the Happy Tails page
#
# Author:
#   Zach Whaley (zachwhaley) <zachbwhaley@gmail.com>

git = require '../lib/git'
site = require '../lib/site'
util = require '../lib/util'

adopt = (greyhound, doa, callback) ->
  site.loadGreyhound greyhound, (info, bio) ->
    if not info?
      return callback "Sorry, couldn't find #{greyhound} 😕"

    if info.category is 'deceased'
      return callback "#{util.display(greyhound)} has crossed the Rainbow Bridge 😢"
    if info.category is 'adopted'
      return callback "#{util.display(greyhound)} has already been adopted 😝"

    info.category = 'adopted'
    info.doa = if doa?
      new Date(doa)
    else
      util.nowDate()
    site.dumpGreyhound greyhound, info, bio, callback

module.exports = (robot) ->
  robot.respond /adopt (.+?)\s*(\d{4}-\d{1,2}-\d{1,2})?$/i, (res) ->
    greyhound = util.sanitize res.match[1]
    doa = res.match[2]
    gitOpts =
      message: "#{util.display(greyhound)} Adopted! 💗"
      branch: "adopt-#{greyhound}"
      user:
        name: res.message.user?.real_name
        email: res.message.user?.profile?.email

    res.reply "Moving #{util.display(greyhound)} to Happy Tails! 💗\n" +
              "Hang on a sec..."

    git.update adopt, greyhound, doa, gitOpts, (update) ->
      res.reply update
