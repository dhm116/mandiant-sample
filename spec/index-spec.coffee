requirejs ['chai', 'request', 'zombie'],
(chai, request, zombie) ->
    expect = chai.expect
    browser = new zombie()

    describe 'Github API sample', ->
        it 'should load the page', (done) ->
            request 'http://localhost:3000', (err, resp, body) ->
                expect(err).to.not.exist
                expect(resp).to.exist
                expect(body).to.exist
                done()

        it 'should contain some commit history entries', (done) ->
            browser.visit('http://localhost:3000')
                .then ->
                    # No errors
                    expect(browser.errors).to.have.length(0)

                    # Make sure there are table rows
                    rows = browser.queryAll('tr')
                    expect(rows).to.have.length.above(0)

                    # Pull out all of the commit hash links
                    shas = browser.queryAll('tr td:last-child a')

                    # Regular expression for checking if string ends with a digit
                    re = /^.*\d$/

                    # Iterate through each commit hash link
                    for link in shas
                        # Get the actual hash value
                        sha = link.getAttribute('data-value')

                        # Determine if this ends with a digit (true) or not (false)
                        shouldHighlight = re.test(sha)

                        # Step back up to the table row containing this commit hash
                        tr = link.parentNode.parentNode

                        # Find out if the table row has the highlighted style applied
                        isHighlighted = if tr.getAttribute('class').indexOf('highlight') > -1 then true else false

                        # Verify it is highlighted if needed
                        expect(isHighlighted).to.be.equal(shouldHighlight)
                .finally done
