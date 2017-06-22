# Git commands

fs = require 'fs'
path = require 'path'
Git = require 'nodegit'
GitHub = require 'github-api'

repoName = 'gpa-centex/gpa-centex.github.io'
repoURL = "https://github.com/#{repoName}.git"
repoPath = path.join __dirname, 'gpa-centex.org'

auth = (url, username) ->
  Git.Cred.userpassPlaintextNew process.env.GITHUB_TOKEN, 'x-oauth-basic'

module.exports =
  pull: (callback) ->
    cloneOpts = fetchOpts: callbacks: credentials: auth
    fs.stat repoPath, (err, stats) ->
      if err
        # Clone
        Git.Clone.clone repoURL, repoPath, cloneOpts
        .then (repository) ->
          callback null, repository
        .catch (err) ->
          callback "Clone #{err}", null
      else
        # Pull
        repo = null
        Git.Repository.open repoPath
        .then (repository) ->
          repo = repository
          repo.fetchAll cloneOpts.fetchOpts
        .then ->
          repo.mergeBranches 'source', 'origin/source'
        .then ->
          repo.checkoutBranch 'source'
        .then ->
          callback null, repo
        .catch (err) ->
          callback "Pull #{err}", repo

  branch: (repo, name, callback) ->
    ref = null
    head = null
    repo.getHeadCommit()
    .then (oid) ->
      head = oid
      Git.Reset.reset repo, head, Git.Reset.TYPE.HARD
    .then (err) ->
      throw "Failed hard reset" if err > 0
      repo.createBranch name, head, true
    .then (reference) ->
      ref = reference
      repo.checkoutBranch ref
    .then ->
      callback null, ref
    .catch (err) ->
      callback "Branch #{err}", ref

  commit: (repo, user, message, callback) ->
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
      author = Git.Signature.now user.name, user.email
      committer = Git.Signature.now 'RooBot', 'roobot@gpa-centex.org'
      repo.createCommit 'HEAD', author, committer, message, tree, [parent]
    .then (oid) ->
      callback null, oid
    .catch (err) ->
      callback "Commit #{err}"

  push: (repo, ref, callback) ->
    repo.getRemote 'origin'
    .then (remote) ->
      pushOpts = callbacks: credentials: auth
      remote.push ["#{ref}:#{ref}"], pushOpts
    .then ->
      callback null
    .catch (err) ->
      callback "Push #{err}"

  pullrequest: (title, head, callback) ->
    github = new GitHub {token: process.env.GITHUB_TOKEN}
    repo = github.getRepo repoName
    repo.createPullRequest {title: title, head: head, base: 'source'}
    .then (res) ->
      callback null, res.data
    .catch (err) ->
      callback "PR #{err}"
