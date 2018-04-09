# Description:
#   Label a greyhound as cat safe or not
#
# Commands:
#   hubot cats <greyhound> (yes/no)- Label a greyhound as cat safe or not
#
# Author:
#   Zach Whaley (zachwhaley) <zachbwhaley@gmail.com>

git = require '../lib/git'
site = require '../lib/site'
util = require '../lib/util'

catString = (catsafe) ->
  return if catsafe then "cat safe! 😸" else "not cat safe 😿"

cats = (greyhound, catsafe, callback) ->
  site.loadGreyhound greyhound, (info, bio) ->
    if not info?
      return callback "Sorry, couldn't find #{greyhound} 😕"

    if info.cats is catsafe
      return callback "#{util.display(greyhound)} is already #{catString(catsafe)} 😝"

    info.cats = catsafe
    site.dumpGreyhound greyhound, info, bio, callback

module.exports = (robot) ->
  robot.respond /cats (.+?)\s*(yes|no)?$/i, (res) ->
    greyhound = util.sanitize res.match[1]
    if res.match[2]?
      catsafe = if res.match[2].toLowerCase() is 'no' then no else yes
    else
      catsafe = yes

    gitOpts =
      message: "#{util.display(greyhound)} is #{catString(catsafe)}"
      branch: "cats-#{greyhound}"
      user:
        name: res.message.user?.real_name
        email: res.message.user?.profile?.email

    res.reply "Labeling #{util.display(greyhound)} as #{catString(catsafe)}\n" +
              "Hang on a sec..."

    git.update cats, greyhound, catsafe, gitOpts, (update) ->
      res.reply update
