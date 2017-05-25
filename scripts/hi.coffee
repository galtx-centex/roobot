# Description:
#   Say Hi! 🤖
#
# Commands:
#   hubot hi - Hi! 🤖
#
# Author:
#   Zach Whaley (zachwhaley) <zachbwhaley@gmail.com>


module.exports = (robot) ->
  robot.respond /hi/i, (res) ->
    res.reply "Hi! 🤖"
