# Git commands
fs = require 'fs'
yaml = require 'yamljs'
path = require 'path'
dateformat = require 'dateformat'
Git = require 'nodegit'
GitHub = require 'github-api'

repoName = 'gpa-centex/gpa-centex.github.io'
repoURL = "https://github.com/#{repoName}.git"
repoPath = path.join __dirname, 'gpa-centex.org'

auth = (url, username) ->
  Git.Cred.userpassPlaintextNew process.env.GITHUB_TOKEN, 'x-oauth-basic'

objEncoder = (value) ->
  if value instanceof Date
    dateformat value, 'isoDate', true
  else
    null

module.exports =
  loadGreyhounds: (callback) ->
    file = "#{repoPath}/_data/greyhounds.yml"
    yaml.load file, (greyhounds) ->
      callback greyhounds

  dumpGreyhounds: (greyhounds, callback) ->
    file = "#{repoPath}/_data/greyhounds.yml"
    data = yaml.dump greyhounds, 2, 2, false, objEncoder
    fs.writeFile file, data, (err) ->
      callback err

  pull: (callback) ->
    cloneOpts = fetchOpts: callbacks: credentials: auth
    fs.stat repoPath, (err, stats) ->
      if err
        # Clone
        Git.Clone.clone repoURL, repoPath, cloneOpts
        .then (repository) ->
          callback repository
      else
        # Pull
        repo = {}
        Git.Repository.open repoPath
        .then (repository) ->
          repo = repository
          repo.fetchAll cloneOpts.fetchOpts
        .then ->
          repo.mergeBranches 'master', 'origin/master'
        .then ->
          repo.checkoutBranch 'master'
        .done ->
          callback repo

  branch: (repo, name, callback) ->
    ref = {}
    repo.getMasterCommit()
    .then (master) ->
      repo.createBranch name, master, true
    .then (reference) ->
      ref = reference
      repo.checkoutBranch ref, {}
    .done ->
      callback ref

  commit: (repo, user, message, callback) ->
    ndx = {}
    tree = {}
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
      author = Git.Signature.now user.name, user.email
      committer = Git.Signature.now 'RooBot', 'roobot@gpa-centex.org'
      repo.createCommit 'HEAD', author, committer, message, tree, [parent]
    .then (oid) ->
      callback oid

  push: (repo, ref, callback) ->
    repo.getRemote 'origin'
    .then (remote) ->
      pushOpts = callbacks: credentials: auth
      remote.push ["#{ref}:#{ref}"], pushOpts
    .done ->
      callback()

  pullrequest: (title, head, callback) ->
    github = new GitHub {token: process.env.GITHUB_TOKEN}
    repo = github.getRepo repoName
    repo.createPullRequest {title: title, head: head, base: 'master'}
    .then (res) ->
      callback res.data
