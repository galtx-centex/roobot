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

fs = require 'fs'
capitalize = require 'capitalize'

git = require './git'

cats = (repo, greyhound, safe, callback) ->
  file = "#{repo.workdir()}/_data/greyhounds.yml"
  fs.readFile file, 'utf8', (err, data) ->
    return callback err if err

    m = data.match ///^#{greyhound}:$///m
    if m is null
      return callback "Sorry, couldn't find #{capitalize(greyhound)} 😕"

    data = data.replace(
      ///^(#{greyhound}:[\s\S]+?)cats:.*///m, (match, p1) ->
        if safe
          "#{p1}cats: yes"
        else
          "#{p1}cats: no"
    )

    fs.writeFile file, data, (err) ->
      callback err

module.exports = (robot) ->
  robot.respond /cats (\w+) (\w+)/i, (res) ->
    catsafe = res.match[1]
    greyhound = res.match[2]

    if catsafe is 'yes'
      catsafe = true
    else if catsafe is 'no'
      catsafe = false
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
        cats repo, greyhound, catsafe, (err) ->
          return res.reply err if err
          git.commit repo, user, message, (oid) ->
            git.push repo, ref, ->
              git.pullrequest message, branch, (pr) ->
                res.reply "Pull Request ready ➜ #{pr.html_url}"
