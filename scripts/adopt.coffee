fs = require 'fs'
git = require './git'

adopt = (repo, greyhound, callback) ->
  file = "#{repo.workdir()}/_data/greyhounds.yml"
  fs.readFile file, 'utf8', (err, data) ->
    if err
      callback err
    err = null
    data = data.replace(
      ///^(#{greyhound}:[\s\S]+?)available:\s(yes|no)///m, (match, p1, p2) ->
        if p2 == 'no'
          err = "#{greyhound} has already been adopted 😝"
        else
          "#{p1}available: no"
    )
    if err
      callback err
    else
      fs.writeFile file, data, (err) ->
        callback err

module.exports = (robot) ->
  robot.respond /adopt (.*)/i, (res) ->
    greyhound = res.match[1]
    message = "#{greyhound} Adopted!"
    branch = "adopt-#{greyhound}"
    # TODO Find user's name and email

    git.pull (repo) ->
      adopt repo, greyhound, (err) ->
        return res.reply err if err
        git.branch repo, branch, (ref) ->
          git.commit repo, message, (oid) ->
            git.push repo, ref, ->
              git.pullrequest message, branch, (pr) ->
                res.reply "Moving #{greyhound} to Happy Tails 💗! #{pr.html_url}"
