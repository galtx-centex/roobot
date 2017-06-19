# Description:
#   Label a greyhound as cat safe or not
#
# Commands:
#   hubot cats <yes|no> <greyhound> - Label a greyhound as cat safe or not
#
# Author:
#   Zach Whaley (zachwhaley) <zachbwhaley@gmail.com>

capitalize = require 'capitalize'

git = require './git'

catString = (catsafe) ->
  return if catsafe then "cat safe! 😸" else "not cat safe 😿"

cats = (greyhound, catsafe, callback) ->
  git.loadGreyhound greyhound, (info, bio) ->
    if not info?
      return callback "Sorry, couldn't find #{greyhound} 😕"

    if info.cats is catsafe
      return callback "#{capitalize(greyhound)} is already #{catString(catsafe)} 😝"

    info.cats = catsafe
    git.dumpGreyhound greyhound, info, bio, callback

module.exports = (robot) ->
  robot.respond /cats (\w+) (\w+)/i, (res) ->
    catsafe = res.match[1]?.toLowerCase()
    greyhound = res.match[2]?.toLowerCase()

    if catsafe not in ['yes', 'no']
      res.reply "I'm not sure what 'cats #{catsafe} #{greyhound}' means 😕\n" +
                "Please use 'cats yes #{greyhound}' or 'cats no #{greyhound}'"
      return
    catsafe = catsafe is 'yes'

    message = "#{capitalize(greyhound)} is #{catString(catsafe)}"
    branch = "cats-#{greyhound}"
    user =
      name: res.message.user?.real_name,
      email: res.message.user?.profile?.email

    res.reply "Labeling #{capitalize(greyhound)} as #{catString(catsafe)}\n" +
              "Hang on a sec..."
    git.pull (err, repo) ->
      return res.reply err if err?
      git.branch repo, branch, (err, ref) ->
        return res.reply err if err?
        cats greyhound, catsafe, (err) ->
          return res.reply err if err?
          git.commit repo, user, message, (err, oid) ->
            return res.reply err if err?
            git.push repo, ref, (err) ->
              return res.reply err if err?
              git.pullrequest message, branch, (err, pr) ->
                return res.reply err if err?
                res.reply "Pull Request ready ➜ #{pr.html_url}"
