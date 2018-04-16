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

fetch = () ->
  new Promise (resolve, reject) ->
    cloneOpts = fetchOpts: callbacks: credentials: auth
    fs.stat repoPath, (err, stats) ->
      if err
        # Clone
        console.log "clone #{repoURL} to #{repoPath}"
        Git.Clone.clone repoURL, repoPath, cloneOpts
        .then (repo) ->
          resolve repo
        .catch (err) ->
          reject "Clone #{err}"
      else
        # Fetch
        repo = null
        console.log "open #{repoPath}"
        Git.Repository.open repoPath
        .then (repo) ->
          console.log "fetch all"
          repo.fetchAll cloneOpts.fetchOpts
          resolve repo
        .catch (err) ->
          reject "Fetch #{err}"

checkout = (repo, branch) ->
  new Promise (resolve, reject) ->
    ref = null
    repo.getReference "origin/#{branch}"
    .then (reference) ->
      ref = reference
      console.log "ref checkout #{ref}"
      repo.checkoutRef ref
    .then () ->
      resolve ref
    .catch (err) ->
      reject "Checkout #{err}"

commit = (repo, user, message) ->
  new Promise (resolve, reject) ->
    ndx = null
    tree = null
    repo.refreshIndex()
    .then (index) ->
      ndx = index
      ndx.addAll()
    .then () ->
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

tag = (repo, oid) ->
  new Promise (resolve, reject) ->
    repo.createLightweightTag oid, "#{oid}-tag"
    .then (reference) ->
      resolve reference
    .catch (err) ->
      reject "Tag #{err}"

push = (repo, src, dst) ->
  new Promise (resolve, reject) ->
    repo.getRemote 'origin'
    .then (remote) ->
      console.log "push #{src}:#{dst}"
      pushOpts = callbacks: credentials: auth
      remote.push ["#{src}:refs/heads/#{dst}"], pushOpts
    .then () ->
      resolve()
    .catch (err) ->
      reject "Push #{err}"

newPullRequest = (title, head) ->
  new Promise (resolve, reject) ->
    console.log "open PR #{title}"
    github = new GitHub {token: process.env.GITHUB_TOKEN}
    repo = github.getRepo repoName
    repo.createPullRequest {title: title, head: head, base: 'source'}
    .then ({data}) ->
      resolve data
    .catch (err) ->
      reject "PR #{err}"

findPullRequest = (head) ->
  new Promise (resolve, reject) ->
    console.log "find PR #{head}"
    github = new GitHub {token: process.env.GITHUB_TOKEN}
    repo = github.getRepo repoName
    repo.listPullRequests {state: 'open', head: "galtx-centex:#{head}"}
    .then ({data}) ->
      if data[0]?
        resolve data[0]
      else
        reject "PR No #{head} Pull Request Found!"
    .catch (err) ->
      reject "PR #{err}"

module.exports =
  findPR: (head, callback) ->
    findPullRequest head
    .then (pr) ->
      console.log "Found PR #{pr.number}: #{pr.title}"
      callback pr, null
    .catch (err) ->
      callback null, err

  update: (action, args..., opts, callback) ->
    fetch()
    .then (repo) ->
      opts.repo = repo
      checkout opts.repo, opts.base ? 'source'
    .then (ref) ->
      new Promise (resolve, reject) ->
        action args..., (err) ->
          unless err?
            resolve()
          else
            reject err
    .then () ->
      commit opts.repo, opts.user, opts.message
    .then (oid) ->
      tag opts.repo, oid
    .then (tag) ->
      push opts.repo, tag, opts.branch
    .then () ->
      newPullRequest opts.message, opts.branch
    .then (pr) ->
      callback "Pull Request ready ➜ #{pr.html_url}"
    .catch (err) ->
      callback err
