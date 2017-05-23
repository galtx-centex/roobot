# Git commands
fs = require 'fs'
path = require 'path'
Git = require 'nodegit'

repoURL = 'git@github.com:gpa-centex/gpa-centex.github.io.git'
repoPath = path.join __dirname, 'website'

ssh = (url, username) ->
  Git.Cred.sshKeyFromAgent username

module.exports =
  pull: (callback) ->
    cloneOpts = fetchOpts: callbacks: credentials: ssh
    fs.stat repoPath, (err, stats) ->
      if err
        # Clone
        Git.Clone repoURL, repoPath, cloneOpts
        .done (repository) ->
          callback repository
          return
      else
        # Pull
        repo = {}
        Git.Repository.open repoPath
        .then (repository) ->
          repo = repository
          repo.fetchAll cloneOpts.fetchOpts
        .then ->
          repo.mergeBranches 'master', 'origin/master'
        .done ->
          callback repo
          return

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
      return

  commit: (repo, message, callback) ->
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
      sig = repo.defaultSignature()
      repo.createCommit 'HEAD', sig, sig, message, tree, [parent]
    .done (oid) ->
      callback oid
      return

  push: (repo, ref, callback) ->
    repo.getRemote 'origin'
    .then (remote) ->
      pushOpts = callbacks: credentials: ssh
      remote.push ["#{ref}:#{ref}"], pushOpts
    .done ->
      callback()
      return
