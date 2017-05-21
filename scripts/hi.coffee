# Say hi

module.exports = (robot) ->
  robot.respond /hi/i, (res) ->
    res.reply "Hi! 🤖"
