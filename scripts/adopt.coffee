# Description:
#   Move an adopted greyhound to the Happy Tails page
#
# Dependencies:
#   "github-api": "3.0.0"
#   "nodegit": "0.18.3"
#
# Commands:
#   hubot adopt <greyhound> - Moves an adopted greyhound to the Happy Tails page
#
# Author:
#   Zach Whaley (zachwhaley) <zachbwhaley@gmail.com>

fs = require 'fs'
git = require './git'

adopt = (repo, greyhound, callback) ->
  file = "#{repo.workdir()}/_data/greyhounds.yml"
  fs.readFile file, 'utf8', (err, data) ->
    return callback err if err

    m = data.match ///^#{greyhound}:$///m
    if m is null
      return callback "Sorry, couldn't find #{greyhound} 😕"

    err = null
    data = data.replace(
      ///^(#{greyhound}:[\s\S]+?)available:\s(yes|no)///m, (match, p1, p2) ->
        if p2 is 'no'
          err = "#{greyhound} has already been adopted 😝"
          return
        "#{p1}available: no"
    )
    return callback err if err

    fs.writeFile file, data, (err) ->
      callback err

module.exports = (robot) ->
  robot.respond /adopt (.*)/i, (res) ->
    greyhound = res.match[1]
    message = "#{greyhound} Adopted!"
    branch = "adopt-#{greyhound}"
    user =
      name: res.message.user.real_name,
      email: res.message.user.profile.email

    res.reply "Moving #{greyhound} to Happy Tails! 💗\nHang on a sec..."
    git.pull (repo) ->
      adopt repo, greyhound, (err) ->
        return res.reply err if err
        git.branch repo, branch, (ref) ->
          git.commit repo, user, message, (oid) ->
            git.push repo, ref, ->
              git.pullrequest message, branch, (pr) ->
                res.reply "Pull Request ready ➜ #{pr.html_url}"
