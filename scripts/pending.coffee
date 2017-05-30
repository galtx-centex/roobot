# Description:
#   Label a greyhound as pending adoption
#
# Commands:
#   hubot pending <greyhound> - Labels a greyhound as pending adoption
#
# Author:
#   Zach Whaley (zachwhaley) <zachbwhaley@gmail.com>

capitalize = require 'capitalize'
git = require './git'

pending = (greyhound, callback) ->
  git.loadGreyhounds (greyhounds) ->
    if greyhound not of greyhounds
      return callback "Sorry, couldn't find #{greyhound} 😕"

    if greyhounds[greyhound].available is no
      return callback "#{capitalize(greyhound)} has already been adopted 😝"

    if greyhounds[greyhound].pending is yes
      return callback "#{capitalize(greyhound)} is already pending adoption 😝"

    greyhounds[greyhound].pending = yes
    git.dumpGreyhounds greyhounds, callback

module.exports = (robot) ->
  robot.respond /pending (.*)/i, (res) ->
    greyhound = res.match[1]
    message = "#{capitalize(greyhound)} Pending Adoption! 🎉"
    branch = "pending-#{greyhound}"
    user =
      name: res.message.user?.real_name?,
      email: res.message.user?.profile?.email?

    res.reply "Labeling #{capitalize(greyhound)} as Pending Adoption! 🎉\n" +
              "Hang on a sec..."
    git.pull (err, repo) ->
      return res.reply err if err?
      git.branch repo, branch, (err, ref) ->
        return res.reply err if err?
        pending greyhound, (err) ->
          return res.reply err if err?
          git.commit repo, user, message, (err, oid) ->
            return res.reply err if err?
            git.push repo, ref, (err) ->
              return res.reply err if err?
              git.pullrequest message, branch, (err, pr) ->
                return res.reply err if err?
                res.reply "Pull Request ready ➜ #{pr.html_url}"
