fs = require 'fs'
git = require './git'

adopt = (repo, greyhound, callback) ->
  res = null
  file = "#{repo.workdir()}/_data/greyhounds.yml"
  fs.readFile file, 'utf8', (err, data) ->
    pass = false
    data = data.replace(
      ///^(#{greyhound}:[\s\S]+?)available:\s(yes|no)///m, (match, p1, p2) ->
        pass = true if p2 == 'yes'
        "#{p1}available: no"
    )
    if pass
      fs.writeFile file, data, (err) ->
        callback true
    else
      callback false, "#{greyhound} has already been adopted. Nothing to do :)"

module.exports = (robot) ->
  robot.respond /adopt (.*)/i, (res) ->
    greyhound = res.match[1]
    message = "#{greyhound} Adopted!"
    branch = "adopt-#{greyhound}"
    # TODO Find user's name and email

    git.pull (repo) ->
      adopt repo, greyhound, (pass, msg) ->
        return res.reply msg if !pass
        git.branch repo, branch, (ref) ->
          git.commit repo, message, (oid) ->
            git.push repo, ref, ->
              git.pullrequest message, branch, (pr) ->
                res.reply "Moving #{greyhound} to Happy Tails! #{pr.html_url}"
