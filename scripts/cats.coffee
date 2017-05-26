# Description:
#   Label a greyhound as cat safe or not
#
# Dependencies:
#   "github-api": "3.0.0"
#   "nodegit": "0.18.3"
#   "capitalize": "1.0.0"
#
# Commands:
#   hubot cats <yes|no> <greyhound> - Label a greyhound as cat safe or not
#
# Author:
#   Zach Whaley (zachwhaley) <zachbwhaley@gmail.com>

capitalize = require 'capitalize'

git = require './git'

cats = (greyhound, catsafe, callback) ->
  git.loadGreyhounds (greyhounds) ->
    if greyhound not of greyhounds
      return callback "Sorry, couldn't find #{greyhound} 😕"

    greyhounds[greyhound].cats = catsafe
    git.dumpGreyhounds greyhounds, callback

module.exports = (robot) ->
  robot.respond /cats (\w+) (\w+)/i, (res) ->
    catsafe = res.match[1]
    greyhound = res.match[2]

    if catsafe is 'yes'
      catsafe = yes
    else if catsafe is 'no'
      catsafe = no
    else
      res.reply "I'm not sure what 'cats #{catsafe} #{greyhound}' means 😕\n" +
                "Please use 'cats yes #{greyhound}' or 'cats no #{greyhound}'"
      return

    catmsg = if catsafe then "cat safe! 😸" else "not cat safe 😿"
    message = "#{capitalize(greyhound)} is #{catmsg}"
    branch = "cats-#{greyhound}"
    user =
      name: res.message.user.real_name,
      email: res.message.user.profile.email

    res.reply "Labeling #{capitalize(greyhound)} as #{catmsg}\n" +
              "Hang on a sec..."
    git.pull (repo) ->
      git.branch repo, branch, (ref) ->
        cats greyhound, catsafe, (err) ->
          return res.reply err if err
          git.commit repo, user, message, (oid) ->
            git.push repo, ref, ->
              git.pullrequest message, branch, (pr) ->
                res.reply "Pull Request ready ➜ #{pr.html_url}"
