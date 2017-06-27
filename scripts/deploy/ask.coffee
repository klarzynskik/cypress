_        = require("lodash")
fs       = require("fs-extra")
glob     = require("glob")
Promise  = require("bluebird")
inquirer = require("inquirer")

glob = Promise.promisify(glob)

prompt = (questions) ->
  Promise.resolve(inquirer.prompt(questions))

fs = Promise.promisifyAll(fs)

module.exports = {

  getZipFile: ->
    [{
      name: "zipFile"
      type: "string"
      message: "Which zip file should we upload?"
    }]

  getPlatformQuestion: ->
    [{
      name: "platform"
      type: "list"
      message: "Which OS should we deploy?"
      choices: [{
        name: "Mac"
        value: "darwin"
      },{
        name: "Linux"
        value: "linux"
      }]
    }]

  getQuestions: (version) ->
    [{
      name: "publish"
      type: "list"
      message: "Publish a new version? (currently: #{version})"
      choices: [{
        name: "Yes: set a new version and deploy new version."
        value: true
      },{
        name: "No:  just override the current deploy’ed version."
        value: false
      }]
    },{
      name: "version"
      type: "input"
      message: "Bump version to...? (currently: #{version})"
      default: ->
        a = version.split(".")
        v = a[a.length - 1]
        v = Number(v) + 1
        a.splice(a.length - 1, 1, v)
        a.join(".")
      when: (answers) ->
        answers.publish
    }]

  getReleases: (releases) ->
    [{
      name: "release"
      type: "list"
      message: "Release which version?"
      choices: _.map releases, (r) ->
        {
          name: r
          value: r
        }
    }]

  getVersions: (releases) ->
    [{
      name: "version"
      type: "list"
      message: "Bump to which version?"
      choices: _.map releases, (r) ->
        {
          name: r
          value: r
        }
    }]

  getBumpTasks: ->
    [{
      name: "task"
      type: "list"
      message: "Which bump task?"
      choices: [{
        name: "Bump Cypress Version for all CI providers"
        value: "version"
      },{
        name: "Run All Projects for all CI providers"
        value: "run"
      }]
    }]

  deployNewVersion: ->
    fs.readJsonAsync("./package.json")
    .then (json) =>
      prompt(@getQuestions(json.version))
      .then (answers) ->
        ## set the new version if we're publishing!
        ## update our own local package.json as well
        if answers.publish
          # @updateLocalPackageJson(answers.version, json).then ->
          answers.version
        else
          json.version

  whichZipFile: () ->
    prompt(@getZipFile())
    .get("zipFile")

  whichVersion: (distDir) ->
    ## realpath returns the absolute full path
    glob("*/package.json", {cwd: distDir, realpath: true})
    .map (pkg) =>
      fs.readJsonAsync(pkg)
      .get("version")
    .then (versions) =>
      versions = _.uniq(versions)

      prompt(@getVersions(versions))
      .get("version")

  whichRelease: (distDir) ->
    ## realpath returns the absolute full path
    glob("*/package.json", {cwd: distDir, realpath: true})
    .map (pkg) =>
      fs.readJsonAsync(pkg)
      .get("version")
    .then (versions) =>
      versions = _.uniq(versions)

      prompt(@getReleases(versions))
      .get("release")

  whichPlatform: ->
    prompt(@getPlatformQuestion())
    .get("platform")

  whichBumpTask: ->
    prompt(@getBumpTasks())
    .get("task")

}
