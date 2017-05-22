# fetch latest (clone if necessary)

module.exports =
  fetch: (callback) ->
    NodeGit = require 'nodegit'
    Path = require 'path'
    Fs = require 'fs'

    repoURL = 'git@github.com:gpa-centex/roobot.git'
    repoPath = Path.join __dirname, 'website'
    cloneOpts = fetchOpts: callbacks: credentials: (url, username) -> NodeGit.Cred.sshKeyFromAgent username

    Fs.stat repoPath, (err, stats) ->
      if err
        # Clone
        NodeGit.Clone repoURL, repoPath, cloneOpts
        .then (repository) ->
          callback repository
          return
      else
        # Pull
        repo = {}
        NodeGit.Repository.open repoPath
        .then (repository) ->
          repo = repository
          repo.fetchAll cloneOpts.fetchOpts
        .then ->
          repo.mergeBranches 'master', 'origin/master'
        .then ->
          callback repo
          return
