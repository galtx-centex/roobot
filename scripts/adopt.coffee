# Description:
#   Move an adopted greyhound to the Happy Tails page
#
# Commands:
#   hubot adopt <greyhound> [m/d/yyyy] - Moves an adopted greyhound to the Happy Tails page
#
# Author:
#   Zach Whaley (zachwhaley) <zachbwhaley@gmail.com>

git = require '../lib/git'
site = require '../lib/site'
util = require '../lib/util'

adopt = (path, greyhound, name, doa, callback) ->
  site.loadGreyhound path, greyhound, (info, bio) ->
    if not info?
      return callback "Sorry, couldn't find #{greyhound} 😕"

    if info.category is 'deceased'
      return callback "#{name} has crossed the Rainbow Bridge 😢"
    if info.category is 'adopted'
      return callback "#{name} has already been adopted 😝"

    info.category = 'adopted'
    info.doa = if doa?
      util.thisDate(doa)
    else
      util.nowDate()
    site.dumpGreyhound path, greyhound, info, bio, callback

module.exports = (robot) ->
  robot.respond /adopt (.+?)\s*(\d{1,2}\/\d{1,2}\/\d{4})?$/i, (res) ->
    greyhound = util.slugify res.match[1]
    name = util.capitalize res.match[1]
    doa = res.match[2]
    gitOpts =
      message: "#{name} Adopted! 💗"
      branch: "adopt-#{greyhound}"
      user:
        name: res.message.user?.real_name
        email: res.message.user?.email_address

    res.reply "Moving #{name} to Happy Tails! 💗\n" +
              "Hang on a sec..."

    git.update adopt, greyhound, name, doa, gitOpts, (err) ->
      unless err?
        res.reply "#{name} moved to Happy Tails! 💗"
      else
        res.reply err
