fs = require 'fs'
git = require './git'

adoptGreyhound = (repo, greyhound, callback) ->
  file = "#{repo.workdir()}/_data/greyhounds.yml"
  fs.readFile file, 'utf8', (err, data) ->
    data = data.replace ///^(#{greyhound}:[\s\S]+?)available:\syes///m, (match, p1) -> "#{p1}available: no"
    fs.writeFile file, data, (err) ->
      callback(file)

module.exports = (robot) ->
  robot.respond /adopt (.*)/i, (res) ->
    greyhound = res.match[1]
    # TODO Find user's name and email

    git.pull (repo) ->
      git.branch repo, "adopt-#{greyhound}", (ref) ->
        adoptGreyhound repo, greyhound, (file) ->
          git.commit repo, "Adopt #{greyhound}", (oid) ->
            git.push repo, ref, ->
              # TODO pull request
              res.reply 'Done!'
