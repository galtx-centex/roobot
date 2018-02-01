# Git commands

fs = require 'fs'
path = require 'path'
Git = require 'nodegit'
GitHub = require 'github-api'
Promise = require 'bluebird'

repoName = 'gpa-centex/gpa-centex.github.io'
repoURL = "https://github.com/#{repoName}.git"
repoPath = path.join __dirname, 'gpa-centex.org'

auth = (url, username) ->
  Git.Cred.userpassPlaintextNew process.env.GITHUB_TOKEN, 'x-oauth-basic'

pull = ->
  new Promise (resolve, reject) ->
    cloneOpts = fetchOpts: callbacks: credentials: auth
    fs.stat repoPath, (err, stats) ->
      if err
        # Clone
        console.log "clone #{repoURL}"
        Git.Clone.clone repoURL, repoPath, cloneOpts
        .then (repository) ->
          resolve repository
        .catch (err) ->
          reject "Clone #{err}"
      else
        # Pull
        repo = null
        console.log "open #{repoPath}"
        Git.Repository.open repoPath
        .then (repository) ->
          repo = repository
          console.log "fetch #{cloneOpts.fetchOpts}"
          repo.fetchAll cloneOpts.fetchOpts
        .then ->
          console.log "merge origin/source -> source"
          repo.mergeBranches 'source', 'origin/source'
        .then ->
          console.log "checkout source"
          repo.checkoutBranch 'source'
        .then ->
          resolve repo
        .catch (err) ->
          reject "Pull #{err}"

branch = (repo, name) ->
  new Promise (resolve, reject) ->
    ref = null
    head = null
    repo.getHeadCommit()
    .then (oid) ->
      head = oid
      console.log "reset #{head}"
      Git.Reset.reset repo, head, Git.Reset.TYPE.HARD
    .then (err) ->
      throw new Error "Failed hard reset" if err > 0
      console.log "branch #{name}"
      repo.createBranch name, head, true
    .then (reference) ->
      ref = reference
      console.log "checkout #{ref}"
      repo.checkoutBranch ref
    .then ->
      resolve ref
    .catch (err) ->
      reject "Branch #{err}"

commit = (repo, user, message) ->
  new Promise (resolve, reject) ->
    ndx = null
    tree = null
    repo.refreshIndex()
    .then (index) ->
      ndx = index
      ndx.addAll()
    .then ->
      ndx.write()
      ndx.writeTree()
    .then (treeObj) ->
      tree = treeObj
      repo.getHeadCommit()
    .then (parent) ->
      console.log "commit '#{message}'"
      author = Git.Signature.now user.name, user.email
      committer = Git.Signature.now 'RooBot', 'roobot@gpa-centex.org'
      repo.createCommit 'HEAD', author, committer, message, tree, [parent]
    .then (oid) ->
      resolve oid
    .catch (err) ->
      reject "Commit #{err}"

push = (repo, ref) ->
  new Promise (resolve, reject) ->
    repo.getRemote 'origin'
    .then (remote) ->
      console.log "push #{ref}"
      pushOpts = callbacks: credentials: auth
      remote.push ["#{ref}:#{ref}"], pushOpts
    .then ->
      resolve()
    .catch (err) ->
      reject "Push #{err}"

pullrequest = (title, head) ->
  new Promise (resolve, reject) ->
    console.log "open PR #{title}"
    github = new GitHub {token: process.env.GITHUB_TOKEN}
    repo = github.getRepo repoName
    repo.createPullRequest {title: title, head: head, base: 'source'}
    .then (res) ->
      resolve res.data
    .catch (err) ->
      reject "PR #{err}"

module.exports =
  update: (action, args..., opts, callback) ->
    pull()
    .then (repo) ->
      opts.repo = repo
      branch opts.repo, opts.branch
    .then (ref) ->
      opts.ref = ref
      new Promise (resolve, reject) ->
        action args..., (err) ->
          unless err?
            resolve()
          else
            reject err
    .then ->
      commit opts.repo, opts.user, opts.message
    .then (oid) ->
      push opts.repo, opts.ref
    .then ->
      pullrequest opts.message, opts.branch
    .then (pr) ->
      callback "Pull Request ready ➜ #{pr.html_url}"
    .catch (err) ->
      callback err
