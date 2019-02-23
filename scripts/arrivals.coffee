# Description:
#   Add a greyhound to the Available Hounds page
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
    res.reply "To add a greyhound, post a picture to #arrivals with a comment in the format below:\n" +
      "\n`name = Name, sex = female/male, dob = YYYY-MM-DD, color = white and black, cats = yes/no`\n\n" +
      "Notice the equals sign between each attribute and its value, and the commas separating each pair of attribute and value."

  robot.listen(
    (msg) ->
      msg.room is 'C5F138J1K' and msg.message?.rawMessage?.upload
    (res) ->
      message = res.message.message
      file = message.rawMessage.files[0]
      info = site.newInfo message.text
      greyhound = util.slugify info.name
      name = util.capitalize info.name
      picUrl = file.thumb_1024 ? file.url_private
      gitOpts =
        branch: "arrival-#{greyhound}"
        user:
          name: message.user?.real_name
          email: message.user?.email_address
      gitOpts.message = "Add #{name}! 🌟"
      res.reply "Adding #{name} to Available Hounds! 🌟\n" +
                "Hang on a sec..."
      git.review arrival, greyhound, picUrl, info, gitOpts, (update) ->
        res.reply update
  )
