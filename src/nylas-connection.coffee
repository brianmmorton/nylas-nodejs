_ = require 'underscore'
clone = require 'clone'
request = require 'request-promise'
Promise = require 'bluebird'
RestfulModel = require './models/restful-model'
RestfulModelCollection = require './models/restful-model-collection'
RestfulModelInstance = require './models/restful-model-instance'
Account = require './models/account'
ManagementAccount = require './models/management-account'
ManagementModelCollection = require './models/management-model-collection'
Thread = require './models/thread'
Contact = require './models/contact'
Message = require './models/message'
Draft = require './models/draft'
File = require './models/file'
Calendar = require './models/calendar'
Event = require './models/event'
Tag = require './models/tag'
Delta = require './models/delta'
Label = require('./models/folder').Label
Folder = require('./models/folder').Folder

Attributes = require './models/attributes'

PACKAGE_JSON = require '../package.json'
SDK_VERSION = PACKAGE_JSON.version

module.exports =
class NylasConnection

  constructor: (@accessToken) ->
    @threads = new RestfulModelCollection(Thread, @)
    @contacts = new RestfulModelCollection(Contact, @)
    @messages = new RestfulModelCollection(Message, @)
    @drafts = new RestfulModelCollection(Draft, @)
    @files = new RestfulModelCollection(File, @)
    @calendars = new RestfulModelCollection(Calendar, @)
    @events = new RestfulModelCollection(Event, @)
    @tags = new RestfulModelCollection(Tag, @)
    @deltas = new Delta(@)
    @labels = new RestfulModelCollection(Label, @)
    @folders = new RestfulModelCollection(Folder, @)
    @account = new RestfulModelInstance(Account, @)

  requestOptions: (options={}) ->
    options = clone(options)
    Nylas = require './nylas'
    options.method ?= 'GET'
    options.url ?= "#{Nylas.apiServer}#{options.path}" if options.path
    options.body ?= {} unless options.formData
    options.json ?= true
    options.downloadRequest ?= false

    # For convenience, If `expanded` param is provided, convert to view:
    # 'expanded' api option
    if options.qs?.expanded?
      if options.qs.expanded is true
        options.qs.view = 'expanded'
      delete options.qs.expanded

    user = if options.path.substr(0,3) == '/a/' then Nylas.appSecret else @accessToken

    if user
      options.auth =
        'user': user
        'pass': '',
        'sendImmediately': true

    options.headers ?= {}
    options.headers['User-Agent'] ?= "Nylas Node SDK v#{SDK_VERSION}"

    return options

  request: (options={}) ->
    options = @requestOptions(options)

    promise = request options

    return promise.then (response, body) ->
      if options.downloadRequest
        return response
      else
        body = JSON.parse(body) if _.isString body
        return body
