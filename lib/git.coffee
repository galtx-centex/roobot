# Git commands

fs = require 'fs'
path = require 'path'
Git = require 'nodegit'
GitHub = require 'github-api'
Promise = require 'bluebird'

repoName = 'galtx-centex/galtx-centex.github.io'
repoURL = "https://github.com/#{repoName}.git"
repoPath = path.join __dirname, 'galtx-centex.org'

auth = (url, username) ->
  Git.Cred.userpassPlaintextNew process.env.GITHUB_TOKEN, 'x-oauth-basic'

pull = (branch) ->
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
          console.log "merge origin/#{branch} -> #{branch}"
          repo.mergeBranches "#{branch}", "origin/#{branch}"
        .then ->
          console.log "checkout #{branch}"
          repo.checkoutBranch "#{branch}"
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
      committer = Git.Signature.now 'RooBot', 'roobot@galtx-centex.org'
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

newPullRequest = (title, head) ->
  new Promise (resolve, reject) ->
    console.log "open PR #{title}"
    github = new GitHub {token: process.env.GITHUB_TOKEN}
    repo = github.getRepo repoName
    repo.createPullRequest {title: title, head: head, base: 'source'}
    .then (res) ->
      resolve res.data
    .catch (err) ->
      reject "PR #{err}"

findPullRequest = (head) ->
  new Promise (resolve, reject) ->
    console.log "find PR #{head}"
    github = new GitHub {token: process.env.GITHUB_TOKEN}
    repo = github.getRepo repoName
    repo.listPullRequests {state: 'open', head: "galtx-centex:#{head}"}
    .then (res) ->
      resolve res[0] ? null
    .catch (err) ->
      reject "PR #{err}"

module.exports =
  pullrequest: (head, callback) ->
    findPullRequest head
    .then (pr) ->
      console.log "Found PR #{pr?.number}: #{pr?.title}"
      callback pr, null
    .catch (err) ->
      callback null, err

  update: (action, args..., opts, callback) ->
    pull 'source'
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
      newPullRequest opts.message, opts.branch
    .then (pr) ->
      callback "Pull Request ready ➜ #{pr.html_url}"
    .catch (err) ->
      callback err

  append: (action, args..., opts, callback) ->
    pull opts.branch
    .then (repo) ->
      opts.repo = repo
      repo.getBranch opts.branch
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
      findPullRequest opts.branch
    .then (pr) ->
      callback "Pull Request updated ➜ #{pr.html_url}"
    .catch (err) ->
      callback err
