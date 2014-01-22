express = require 'express'
engines = require 'consolidate'
# routes  = require './routes'
Github = require 'github'
Q = require 'q'

# Boilerplate mimosa app template
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

    # Expose moment.js to the Jade template engine
    app.locals.moment = require('moment')

  app.configure 'development', ->
    app.use express.errorHandler()

  # Move logic from routes/index.coffee for simplicity
  options =
    reload:    config.liveReload.enabled
    optimize:  config.isOptimize ? false
    cachebust: if process.env.NODE_ENV isnt "production" then "?b=#{(new Date()).getTime()}" else ''

  # Github API reference
  gh = new Github {
      version: '3.0.0'
      timeout: 5000
  }

  # Wrap our github api call in a promise
  getCommits = (author) ->
    d = Q.defer()

    # Default repo parameters
    query = {user:'joyent',repo:'node'}

    # Check if an author has been specified
    if author
      query.author = author
      console.log "Filtering on author = #{author}"

    # Load the commit history for this repo
    gh.repos.getCommits query, (err, commits) ->
      if err
        # TODO should fail a little more gracefully here
        console.warn(err)
      else
        # Got our results, complete the promise
        d.resolve(commits)

    # Return the promise
    return d.promise

  # Main index route
  #
  # author is an optional argument
  app.get '/:author?', (req, res) ->
    # In the event plain html pages are being used, need to
    # switch to different page for optimized view
    name = if config.isOptimize and config.server.views.html
      "index-optimize"
    else
      "index"

    # Pull out the author from the URL path if it was specified
    author = if req.params.author then req.params.author else null

    # Load the commit history
    getCommits(author).then (commits) ->
      # Supply the commit history to the template
      options.commits = commits
      # Supply the author to the template
      options.author = author

      # Render the view
      res.render name, options

  callback(server)

