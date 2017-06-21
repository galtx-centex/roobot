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
  git.loadGreyhound greyhound, (info, bio) ->
    if not info?
      return callback "Sorry, couldn't find #{greyhound} 😕"

    if info.category is 'deceased'
      return callback "#{capitalize(greyhound)} has crossed the Rainbow Bridge 😢"
    if info.category is 'adopted'
      return callback "#{capitalize(greyhound)} has already been adopted 😝"
    if info.pending is yes
      return callback "#{capitalize(greyhound)} is already pending adoption 😝"

    info.pending = yes
    git.dumpGreyhound greyhound, info, bio, callback

module.exports = (robot) ->
  robot.respond /pending (.*)/i, (res) ->
    greyhound = res.match[1]?.toLowerCase()
    message = "#{capitalize(greyhound)} Pending Adoption! 🎉"
    branch = "pending-#{greyhound}"
    user =
      name: res.message.user?.real_name,
      email: res.message.user?.profile?.email

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
