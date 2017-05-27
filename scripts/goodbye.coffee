# Description:
#   Move an deceased greyhound to the Rainbow Bridge page
#
# Commands:
#   hubot goodbye <greyhound> [yyyy-mm-dd] - Moves a deceased greyhound to the Rainbow Bridge page
#
# Author:
#   Zach Whaley (zachwhaley) <zachbwhaley@gmail.com>

capitalize = require 'capitalize'

git = require './git'

goodbye = (greyhound, dod, callback) ->
  git.loadGreyhounds (greyhounds) ->
    if greyhound not of greyhounds
      return callback "Sorry, couldn't find #{greyhound} 😕"

    if greyhounds[greyhound].deceased is yes
      return callback "#{capitalize(greyhound)} has already crossed the Rainbow Bridge 😢"

    greyhounds[greyhound].deceased = yes
    greyhounds[greyhound].dod = new Date(dod) if dod?
    git.dumpGreyhounds greyhounds, callback

module.exports = (robot) ->
  robot.respond /goodbye (\w+)\s?(\d\d\d\d-\d{1,2}-\d{1,2})?/i, (res) ->
    greyhound = res.match[1]
    dod = res.match[2]
    message = "#{capitalize(greyhound)} crossed the Rainbow Bridge 😢"
    branch = "goodbye-#{greyhound}"
    user =
      name: res.message.user?.real_name?,
      email: res.message.user?.profile?.email?

    res.reply "Moving #{capitalize(greyhound)} to the Rainbow Bridge 😢\n" +
              "Hang on a sec..."
    git.pull (repo) ->
      git.branch repo, branch, (ref) ->
        goodbye greyhound, dod, (err) ->
          return res.reply err if err
          git.commit repo, user, message, (oid) ->
            git.push repo, ref, ->
              git.pullrequest message, branch, (pr) ->
                res.reply "Pull Request ready ➜ #{pr.html_url}"
