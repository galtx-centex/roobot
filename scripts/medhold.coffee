# Description:
#   Label a greyhound as medical hold
#
# Commands:
#   hubot medhold <greyhound> (yes/no) - Labels a greyhound as medical hold.
#
# Author:
#   Zach Whaley (zachwhaley) <zachbwhaley@gmail.com>

git = require '../lib/git'
site = require '../lib/site'
util = require '../lib/util'

medholdMessage = (medicalhold) ->
  if medicalhold
    "in Medical Hold 🤕"
  else
    "not in Medical Hold 😃"

medicalHold = (greyhound, name, medicalhold, callback) ->
  site.loadGreyhound greyhound, (info, bio) ->
    if not info?
      return callback "Sorry, couldn't find #{greyhound} 😕"

    if info.category is 'deceased'
      return callback "#{name} has crossed the Rainbow Bridge 😢"
    if info.category is 'adopted'
      return callback "#{name} has already been adopted 😝"
    if info.permafoster is yes
      return callback "#{name} is a permanent foster 😕\nRemove #{name} permanent foster status first with `@roobot permafoster #{greyhound} no`"
    if info.pending is yes
      return callback "#{name} is pending adoption 😕\nRemove #{name} pending adoption status first with `@roobot pending #{greyhound} no`"
    if medicalhold and info.medicalhold is yes
      return callback "#{name} is already in medical hold 🤕"
    if not medicalhold and info.medicalhold is no
      return callback "#{name} is already not in medical hold 😃"

    info.medicalhold = medicalhold
    site.dumpGreyhound greyhound, info, bio, callback

module.exports = (robot) ->
  robot.respond /medhold (.+?)(\s(yes|no))?$/i, (res) ->
    greyhound = util.slugify res.match[1]
    name = util.capitalize res.match[1]
    medhold = yes
    if res.match[3]?.toLowerCase() is 'no'
      medhold = no

    gitOpts =
      message: "#{name} #{medholdMessage(medhold)}"
      branch: "medhold-#{greyhound}"
      user:
        name: res.message.user?.real_name
        email: res.message.user?.email_address

    res.reply "Labeling #{name} as #{medholdMessage(medhold)}\n" +
              "Hang on a sec..."

    git.update medicalHold, greyhound, name, medhold, gitOpts, (err) ->
      unless err?
        res.reply "#{name} labeled as #{medholdMessage(medhold)}"
      else
        res.reply err
