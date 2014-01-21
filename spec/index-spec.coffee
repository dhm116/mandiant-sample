requirejs ['chai', 'github'],
(chai, Github) ->
    expect = chai.expect

    describe 'Github API', ->
        gh = null

        beforeEach (done) ->
            gh = new Github {
                version: '3.0.0'
                timeout: 5000
            }
            done()

        afterEach (done) ->
            done()

        it 'should find the joyent/node repo', (done) ->
            gh.repos.get {user:'joyent',repo:'node'}, (err, repo) ->
                expect(err).to.not.exist
                expect(repo).to.exist
                done()

        it 'should get the latest joyent/node commits', (done) ->
            gh.repos.getCommits {user:'joyent',repo:'node'}, (err, commits) ->
                expect(err).to.not.exist
                expect(commits).to.exist
                expect(commits).to.have.length(30)
                done()
