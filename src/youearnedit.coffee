# Description:
#   A Hubot script to interact with YouEarnedIt
#
# Configuration:
#   HUBOT_YEI_USERNAME - The YouEarnedIt API "username"
#   HUBOT_YEI_PASS - The YouEarnedIt API "password"
#
# Commands:
#   hubot show my point[s]
#   hubot point[s] me
#   hubot give <name> <amount_of_points> <message>
#
# Author:
#   jeffbyrnes

# Grab Slack API key from EnvVars
slackApiKey = process.env.HUBOT_SLACK_TOKEN
slackURL    = 'https://slack.com/api'
yeiUsername = process.env.HUBOT_YEI_USERNAME
yeiPass     = process.env.HUBOT_YEI_PASS
yeiURL      = 'https://api.youearnedit.com'
auth        = 'Basic ' + new Buffer("#{ yeiUsername}:#{ yeiPass }").toString('base64')

module.exports = (robot) ->
  robot.respond /give\s+(\S+)\s+(\d*)\s+(.*)$/i, (msg) ->
    recipient =
      id:    null
      name:  escape(msg.match[1]).replace /@/, ''
      email: null
    sender      = msg.message.user
    amount      = escape(msg.match[2])
    giftMessage = msg.match[3]

    # Get the recipient's email
    getSlackMembers msg, (slackMembers) ->
      for own key, member of slackMembers
        if member.name == recipient.name
          recipient.id    = member.id
          recipient.email = member.profile.email

      if !recipient.email then return msg.send "Couldn’t find an email address for #{ recipient.name }"

      # Get the sender's email
      unless sender.email
        getUserEmail msg.message.user.id, msg, (senderEmail) ->
          sender.email = senderEmail

      getYeiUser msg, recipient.email, (recipientYei) ->
        unless recipientYei then return msg.send "Couldn’t find YEI user #{ recipient.name }"

        getYeiUser msg, sender.email, (senderYei) ->
          unless senderYei then return msg.send "Couldn’t find your YouEarnedIt user"
          if amount > senderYei.points_to_give
            return msg.send "@#{ sender.name } doesn't have #{ amount } points."

          data = JSON.stringify({
            activity: {
              sender_id: senderYei.id,
              recipient_id: recipientYei.id,
              points: amount,
              description: giftMessage
            }
          })

          msg.robot.http( "#{ yeiURL }/activity" )
            .header('Authorization', auth)
            .header('Accept', 'application/json')
            .header('Content-Type', 'application/json')
            .post(data) (err, res, body) ->
              if err then return msg.send JSON.stringify err

              json = JSON.parse(body)

              if !json.errors && !json.error
                msg.send "@#{ sender.name } gave @#{ recipient.name } #{ amount } points!"
              else
                msg.send JSON.stringify json

  robot.respond /show\s+my\s+points?|points?\s+me/i, (msg) ->
    getUserEmail msg.message.user.id, msg, (email) ->
      getYeiUser msg, email, (yeiUser) ->
        if yeiUser
          msg.send(
            "@#{ msg.message.user.name }\n"
            "Points to Redeem: #{ yeiUser.points_to_redeem }\n"
            "Points to Give: #{ yeiUser.points_to_give }"
          )
        else
          msg.send "@#{ msg.message.user.name } couldn’t find you on YouEarnedIt."

getSlackMembers = (msg, callback) ->
  msg.robot.http( "#{slackURL}/users.list?token=#{ slackApiKey }" )
    .get() (err, res, body) ->
      if err then return msg.send JSON.stringify err

      callback JSON.parse(body).members

getSlackUser = (userId, msg, callback) ->
  msg.robot.http( "#{slackURL}/users.info?token=#{ slackApiKey }&user=#{ userId }" )
    .get() (err, res, body) ->
      if err then return msg.send JSON.stringify err

      body = JSON.parse(body)

      unless body.ok then return msg.send "@#{ msg.message.user.name }, seems something went awry: #{ body.error }"

      callback body.user

getUserEmail = (userId, msg, callback) ->
  if msg.message.user.email and userId == msg.message.user.id
    callback msg.message.user.email

  getSlackUser userId, msg, (user) ->
    email = user.profile.email

    if !email then return msg.send "@#{ msg.message.user.name }, couldn’t find
                                    the email address for user ID #{ userId }."

    callback email

getYeiUser = (msg, email, callback) ->
  msg.robot.http( "#{ yeiURL }/users?email=#{ email }" )
    .header('Authorization', auth)
    .header('Accept', 'application/json')
    .header('Content-Type', 'application/json')
    .get() (err, res, body) ->
      if err then return msg.send JSON.stringify err

      yeiResponse = JSON.parse(body)

      callback yeiResponse[0].user
