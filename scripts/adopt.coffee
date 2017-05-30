# Description:
#   Move an adopted greyhound to the Happy Tails page
#
# Commands:
#   hubot adopt <greyhound> - Moves an adopted greyhound to the Happy Tails page
#
# Author:
#   Zach Whaley (zachwhaley) <zachbwhaley@gmail.com>

capitalize = require 'capitalize'

git = require './git'

adopt = (greyhound, callback) ->
  git.loadGreyhounds (greyhounds) ->
    if greyhound not of greyhounds
      return callback "Sorry, couldn't find #{greyhound} 😕"

    if greyhounds[greyhound].available is no
      return callback "#{capitalize(greyhound)} has already been adopted 😝"

    greyhounds[greyhound].available = no
    git.dumpGreyhounds greyhounds, callback

module.exports = (robot) ->
  robot.respond /adopt (.*)/i, (res) ->
    greyhound = res.match[1]?.toLowerCase()
    message = "#{capitalize(greyhound)} Adopted! 💗"
    branch = "adopt-#{greyhound}"
    user =
      name: res.message.user?.real_name,
      email: res.message.user?.profile?.email

    res.reply "Moving #{capitalize(greyhound)} to Happy Tails! 💗\n" +
              "Hang on a sec..."
    git.pull (err, repo) ->
      return res.reply err if err?
      git.branch repo, branch, (err, ref) ->
        return res.reply err if err?
        adopt greyhound, (err) ->
          return res.reply err if err?
          git.commit repo, user, message, (err, oid) ->
            return res.reply err if err?
            git.push repo, ref, (err) ->
              return res.reply err if err?
              git.pullrequest message, branch, (err, pr) ->
                return res.reply err if err?
                res.reply "Pull Request ready ➜ #{pr.html_url}"
