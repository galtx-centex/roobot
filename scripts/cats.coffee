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

catMessage = (catsafe) ->
  if catsafe
    "cat safe! 😸"
  else
    "not cat safe 😿"

cats = (greyhound, name, catsafe, callback) ->
  site.loadGreyhound greyhound, (info, bio) ->
    if not info?
      return callback "Sorry, couldn't find #{greyhound} 😕"

    if info.cats is catsafe
      return callback "#{name} is already #{catMessage(catsafe)}"

    info.cats = catsafe
    site.dumpGreyhound greyhound, info, bio, callback

module.exports = (robot) ->
  robot.respond /cats (.+?)(\s(yes|no))?$/i, (res) ->
    greyhound = util.slugify res.match[1]
    name = util.capitalize res.match[1]
    catsafe = yes
    if res.match[3]?.toLowerCase() is 'no'
      catsafe = no

    gitOpts =
      message: "#{name} is #{catMessage(catsafe)}"
      branch: "cats-#{greyhound}"
      user:
        name: res.message.user?.real_name
        email: res.message.user?.profile?.email

    res.reply "Labeling #{name} as #{catMessage(catsafe)}\n" +
              "Hang on a sec..."

    git.update cats, greyhound, name, catsafe, gitOpts, (update) ->
      res.reply update
