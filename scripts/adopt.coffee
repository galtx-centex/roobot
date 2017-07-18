# Description:
#   Move an adopted greyhound to the Happy Tails page
#
# Commands:
#   hubot adopt <greyhound> [yyyy-mm-dd] - Moves an adopted greyhound to the Happy Tails page
#
# Author:
#   Zach Whaley (zachwhaley) <zachbwhaley@gmail.com>

capitalize = require 'capitalize'

git = require '../lib/git'
gms = require '../lib/gms'
site = require '../lib/site'

adopt = (greyhound, doa, callback) ->
  site.loadGreyhound greyhound, (info, bio) ->
    if not info?
      return callback "Sorry, couldn't find #{greyhound} 😕"

    if info.category is 'deceased'
      return callback "#{capitalize(greyhound)} has crossed the Rainbow Bridge 😢"
    if info.category is 'adopted'
      return callback "#{capitalize(greyhound)} has already been adopted 😝"

    info.category = 'adopted'
    if doa?
      info.doa = new Date doa
    else
      now = new Date()
      info.doa = new Date Date.UTC(now.getFullYear(), now.getMonth(), now.getDate())
    site.dumpGreyhound greyhound, info, bio, callback

module.exports = (robot) ->
  robot.respond /adopt (\w+)\s?(\d{4}-\d{1,2}-\d{1,2})?/i, (res) ->
    greyhound = res.match[1]?.toLowerCase()
    doa = res.match[2]
    gitOpts =
      message: "#{capitalize(greyhound)} Adopted! 💗"
      branch: "adopt-#{greyhound}"
      user:
        name: res.message.user?.real_name
        email: res.message.user?.profile?.email

    res.reply "Moving #{capitalize(greyhound)} to Happy Tails! 💗\n" +
              "Hang on a sec..."

    git.update adopt, greyhound, doa, gitOpts, (update) ->
      res.reply update

    gms.update 'ADOPT', greyhound, doa, (update) ->
      res.reply update
