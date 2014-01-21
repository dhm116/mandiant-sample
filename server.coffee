express = require 'express'
engines = require 'consolidate'
# routes  = require './routes'
Github = require 'github'
Q = require 'q'

exports.startServer = (config, callback) ->

  port = process.env.PORT or config.server.port

  app = express()
  server = app.listen port, ->
    console.log "Express server listening on port %d in %s mode", server.address().port, app.settings.env

  app.configure ->
    app.set 'port', port
    app.set 'views', config.server.views.path
    app.engine config.server.views.extension, engines[config.server.views.compileWith]
    app.set 'view engine', config.server.views.extension
    app.use express.favicon()
    app.use express.urlencoded()
    app.use express.json()
    app.use express.methodOverride()
    app.use express.compress()
    app.use config.server.base, app.router
    app.use express.static(config.watch.compiledDir)

    app.locals.moment = require('moment')

  app.configure 'development', ->
    app.use express.errorHandler()

  options =
    reload:    config.liveReload.enabled
    optimize:  config.isOptimize ? false
    cachebust: if process.env.NODE_ENV isnt "production" then "?b=#{(new Date()).getTime()}" else ''

  gh = new Github {
      version: '3.0.0'
      timeout: 5000
  }

  commitCache = []
  contributorCache = []

  getCommits = (author) ->
    d = Q.defer()

    unless commitCache.length > 0 and author is null
      query = {user:'joyent',repo:'node'}
      if author
        query.author = author
        query.per_page = 20
        console.log "Filtering on author = #{author}"
      gh.repos.getCommits query, (err, commits) ->
        if err
          console.warn(err)
        else
          commitCache = commits
          d.resolve(commits)
    else
      d.resolve(commitCache)

    return d.promise

  getContributors = ->
    d = Q.defer()
    unless contributorCache.length > 0
      gh.repos.getContributors {user:'joyent',repo:'node'}, (err, contributors) ->
        if err
        else
          contributorCache = contributors
          d.resolve(contributors)
    else
      d.resolve(contributorCache)

    return d.promise

  app.get '/:author?', (req, res) -> #routes.index(config)
    # In the event plain html pages are being used, need to
    # switch to different page for optimized view
    name = if config.isOptimize and config.server.views.html
      "index-optimize"
    else
      "index"

    author = if req.params.author then req.params.author else null

    Q.all([getCommits(author), getContributors()]).spread (commits, contributors) ->
      options.commits = commits
      options.contributors = contributors
      options.author = author
      res.render name, options

  callback(server)

