# hubot-youearnedit

[![Build Status](http://img.shields.io/travis/jeffbyrnes/hubot-youearnedit.svg)](https://travis-ci.org/jeffbyrnes/hubot-youearnedit)

A Hubot script to interact with the YouEarnedIt API from a Slack organization.

It should be noted that, as of 2015-10-15, the v1 API that this utilizes 
will be shut down. A refactor is currently in-progress to bring this up-to-date with v2 of YouEarnedIt’s API.

See [YouEarnedIt’s API docs](https://docs.google.com/document/d/1wHIlGmkBJy5UH9-FbehlfGUxRoS8EVB7oaL7tUklS5k/edit?usp=sharing) for details.

## Installation

In hubot project repo, run:

```bash
$ npm install hubot-youearnedit --save
```

Then add `hubot-youearnedit` to your `external-scripts.json`:

```json
["hubot-youearnedit"]
```

Finally, set the necessary EnvVars:

```bash
$ heroku config:set \
    HUBOT_SLACK_TOKEN='xyz' \
    HUBOT_YEI_USERNAME='xyz' \
    HUBOT_YEI_PASS='xyz'
```

The Slack API token is needed to search Slack’s list of users, in order to ascertain a user’s email address. This is needed to match to a user in YouEarnedIt, as email is the only likely constant between the two services.
