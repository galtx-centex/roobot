# Description:
#   Add a greyhound to the Available Hounds page
#   Add a picture to a greyhound's bio
#
# Commands:
#   hubot add - Show help text to add a greyhound
#   arrivals - Find out how to add a greyhound by asking "@roobot add?"
#
# Author:
#   Zach Whaley (zachwhaley) <zachbwhaley@gmail>

path = require 'path'
image = require 'imagemagick'

git = require '../lib/git'
site = require '../lib/site'
util = require '../lib/util'

arrival = (greyhound, picUrl, info, callback) ->
  fileName = site.newGreyhound greyhound
  picName = "#{fileName}#{path.extname(picUrl)}"
  picPath = "#{site.sitePath}/img/#{picName}"
  info.pic = picName

  util.download picUrl, picPath, (err) ->
    if err?
      return callback "Download Error: #{err}"
    # Make thumbnail
    thmPath = "#{site.sitePath}/img/thm/#{picName}"
    image.convert [picPath, '-thumbnail', '300x300^', '-gravity', 'center', '-extent', '300x300', thmPath], (err) ->
      if err?
        return callback "Thumbnail Error: #{err}"
      site.dumpGreyhound fileName, info, "", callback

addPic = (greyhound, picUrl, callback) ->
  site.loadGreyhound greyhound, (info, bio) ->
    if not info?
      return callback "Sorry, couldn't find #{greyhound} 😕"

    picNum = info.pics?.length ? 0
    picName = "#{greyhound}_#{picNum + 1}#{path.extname(picUrl)}"
    picPath = "#{site.sitePath}/img/#{picName}"

    util.download picUrl, picPath, (err) ->
      if err?
        return callback "Download Error: #{err}"
      info.pics = [picName] unless info.pics?.push picName
      site.dumpGreyhound greyhound, info, bio, callback

module.exports = (robot) ->
  # arrival help text
  robot.respond /add/i, (res) ->
    res.reply "To add a greyhound, post a picture to #arrivals with the greyhound's name as the file name and a comment in the format below:\n" +
      "\n`sex = female|male, dob = 2017-01-21, color = white and black, cats = yes|no`\n\n" +
      "Notice the equals sign between each attribute and its value, and the commas separating each pair of attribute and value.\n" +
      "If no comment is added, the picture will be added to the greyhound whose name is the file name."

  robot.listen(
    (msg) ->
      msg.room is 'C5F138J1K' and msg.message?.rawMessage?.upload
    (res) ->
      message = res.message.message
      file = message.rawMessage.files[0]
      greyhound = util.slugify file.title
      name = util.capitalize file.title
      picUrl = file.thumb_1024 ? file.url_private
      gitOpts =
        branch: "arrival-#{greyhound}"
        user:
          name: message.user?.real_name
          email: message.user?.email_address

      if message.text
        info = site.newInfo greyhound, message.text
        gitOpts.message = "Add #{name}! 🌟"
        res.reply "Adding #{name} to Available Hounds! 🌟\n" +
                  "Hang on a sec..."
        git.review arrival, greyhound, picUrl, info, gitOpts, (update) ->
          res.reply update
      else
        gitOpts.message = "Add pic for #{name}! 😁"
        res.reply "Adding new pic for #{name}! 😁\n" +
                  "Hang on a sec..."
        git.review addPic, greyhound, picUrl, gitOpts, (update) ->
          res.reply update
  )
