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
  git.loadGreyhound greyhound, (info, bio) ->
    if not info?
      return callback "Sorry, couldn't find #{greyhound} 😕"

    if info.category is 'deceased'
      return callback "#{capitalize(greyhound)} has already crossed the Rainbow Bridge 😢"

    info.category = 'deceased'
    info.dod = new Date(dod) if dod?
    git.dumpGreyhound greyhound, info, bio, callback

module.exports = (robot) ->
  robot.respond /goodbye (\w+)\s?(\d\d\d\d-\d{1,2}-\d{1,2})?/i, (res) ->
    greyhound = res.match[1]?.toLowerCase()
    dod = res.match[2]
    message = "#{capitalize(greyhound)} crossed the Rainbow Bridge 😢"
    branch = "goodbye-#{greyhound}"
    user =
      name: res.message.user?.real_name,
      email: res.message.user?.profile?.email

    res.reply "Moving #{capitalize(greyhound)} to the Rainbow Bridge 😢\n" +
              "Hang on a sec..."
    git.pull (err, repo) ->
      return res.reply err if err?
      git.branch repo, branch, (err, ref) ->
        return res.reply err if err?
        goodbye greyhound, dod, (err) ->
          return res.reply err if err?
          git.commit repo, user, message, (err, oid) ->
            return res.reply err if err?
            git.push repo, ref, (err) ->
              return res.reply err if err?
              git.pullrequest message, branch, (err, pr) ->
                return res.reply err if err?
                res.reply "Pull Request ready ➜ #{pr.html_url}"
