# Description:
#   Move an adopted greyhound to the Happy Tails page
#
# Dependencies:
#   "github-api": "3.0.0"
#   "nodegit": "0.18.3"
#   "capitalize": "1.0.0"
#
# Commands:
#   hubot adopt <greyhound> - Moves an adopted greyhound to the Happy Tails page
#
# Author:
#   Zach Whaley (zachwhaley) <zachbwhaley@gmail.com>

capitalize = require 'capitalize'

git = require './git'

adopt = (greyhound, callback) ->
  git.load_greyhounds (greyhounds) ->
    if greyhound not of greyhounds
      return callback "Sorry, couldn't find #{greyhound} 😕"

    if greyhounds[greyhound].available is no
      return callback "#{capitalize(greyhound)} has already been adopted 😝"

    greyhounds[greyhound].available = no
    git.dump_greyhounds greyhounds, callback

module.exports = (robot) ->
  robot.respond /adopt (.*)/i, (res) ->
    greyhound = res.match[1]
    message = "#{capitalize(greyhound)} Adopted! 💗"
    branch = "adopt-#{greyhound}"
    user =
      name: res.message.user.real_name,
      email: res.message.user.profile.email

    res.reply "Moving #{capitalize(greyhound)} to Happy Tails! 💗\n" +
              "Hang on a sec..."
    git.pull (repo) ->
      git.branch repo, branch, (ref) ->
        adopt greyhound, (err) ->
          return res.reply err if err
          git.commit repo, user, message, (oid) ->
            git.push repo, ref, ->
              git.pullrequest message, branch, (pr) ->
                res.reply "Pull Request ready ➜ #{pr.html_url}"
