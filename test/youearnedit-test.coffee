path = require 'path'
fs = require 'fs'
Robot = require 'hubot/src/robot'
TextMessage = require('hubot/src/message').TextMessage
chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'
{ expect } = chai

loadFixture = (name)->
  JSON.parse fs.readFileSync "spec/fixtures/#{name}.json"

describe 'youearnedit', ->
  robot = undefined
  user = undefined
  adapter = undefined

  beforeEach ->
    # create new robot, without http, using the mock adapter
    robot = new Robot null, 'mock-adapter', yes, 'TestHubot'

  afterEach ->
    robot.server.close()
    robot.shutdown()

  describe 'when ENV is not set', ->
    it 'should throw error', (done)->
      sinon.spy robot.logger, 'error'
      robot.adapter.on 'connected', ->
        try
          delete process.env.HUBOT_SLACK_TOKEN
          delete process.env.HUBOT_YEI_USERNAME
          delete process.env.HUBOT_YEI_PASS

          robot.loadFile path.resolve('.', 'src'), 'youearnedit.coffee'

          expect(robot.logger.error).to.have.been.called
          expect(robot.youearnedit).not.to.be.defined

          do done
        catch e
          done e
      do robot.run

  describe 'when ENV is set', ->
    beforeEach (done)->
      process.env.HUBOT_SLACK_TOKEN = 'xoxb-1234567890-aaaaaaaaaaaaaaaaaaaaaaaa'
      process.env.HUBOT_YEI_USERNAME = 'hubot'
      process.env.HUBOT_YEI_PASS = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'

      robot.adapter.on 'connected', ->
        robot.loadFile path.resolve('.', 'src'), 'youearnedit.coffee'
        user = robot.brain.userForId '1', {
          name: 'jeffbyrnes'
          room: '#mocha'
        }
        adapter = robot.adapter

        waitForHelp = ->
          if robot.helpCommands().length > 0
            do done
          else
            setTimeout waitForHelp, 100
        do waitForHelp
      do robot.run

    describe 'help', ->
      it 'should have 3', (done)->
        expect(robot.helpCommands()).to.have.length 3
        do done

      it 'has help messages', ->
        expect(robot.helpCommands()).to.eql [
          'hubot give <name> <amount_of_points> <message>'
          'hubot point[s] me'
          'hubot show my point[s]'
        ]
