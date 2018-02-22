# Description:
#   Label a greyhound as cat safe or not
#
# Commands:
#   hubot cats <yes|no> <greyhound> - Label a greyhound as cat safe or not
#
# Author:
#   Zach Whaley (zachwhaley) <zachbwhaley@gmail.com>

capitalize = require 'capitalize'

git = require '../lib/git'
site = require '../lib/site'

catString = (catsafe) ->
  return if catsafe then "cat safe! 😸" else "not cat safe 😿"

cats = (greyhound, catsafe, callback) ->
  site.loadGreyhound greyhound, (info, bio) ->
    if not info?
      return callback "Sorry, couldn't find #{greyhound} 😕"

    if info.cats is catsafe
      return callback "#{capitalize.words(greyhound)} is already #{catString(catsafe)} 😝"

    info.cats = catsafe
    site.dumpGreyhound greyhound, info, bio, callback

module.exports = (robot) ->
  robot.respond /cats (\w+) (\w+)/i, (res) ->
    catsafe = res.match[1]?.toLowerCase()
    greyhound = res.match[2]?.toLowerCase()
    if catsafe not in ['yes', 'no']
      res.reply "I'm not sure what 'cats #{catsafe} #{greyhound}' means 😕\n" +
                "Please use 'cats yes #{greyhound}' or 'cats no #{greyhound}'"
      return
    catsafe = catsafe is 'yes'

    gitOpts =
      message: "#{capitalize.words(greyhound)} is #{catString(catsafe)}"
      branch: "cats-#{greyhound}"
      user:
        name: res.message.user?.real_name
        email: res.message.user?.profile?.email

    res.reply "Labeling #{capitalize.words(greyhound)} as #{catString(catsafe)}\n" +
              "Hang on a sec..."

    git.update cats, greyhound, catsafe, gitOpts, (update) ->
      res.reply update
