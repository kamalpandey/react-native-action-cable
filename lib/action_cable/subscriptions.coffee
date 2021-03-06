INTERNAL = require('./internal')
Subscription = require('./subscription')

class Subscriptions
  constructor: (@consumer) ->
    @subscriptions = []

  create: (channelName) =>
    channel = channelName
    params = if typeof channel is 'object' then channel else {channel}
    subscription = new Subscription @consumer, params
    @add(subscription)

  # Private

  add: (subscription) =>
    @subscriptions.push(subscription)
    @consumer.ensureActiveConnection()
    @notify(subscription, "initialized")
    @sendCommand(subscription, "subscribe")
    subscription

  remove: (subscription) =>
    @forget(subscription)
    unless @findAll(subscription.identifier).length
      @sendCommand(subscription, "unsubscribe")
    subscription

  reject: (identifier) =>
    for subscription in @findAll(identifier)
      @forget(subscription)
      @notify(subscription, "rejected")
      subscription

  forget: (subscription) =>
    @subscriptions = (s for s in @subscriptions when s isnt subscription)
    subscription

  findAll: (identifier) =>
    s for s in @subscriptions when s.identifier is identifier

  reload: =>
    for subscription in @subscriptions
      @sendCommand(subscription, "subscribe")

  notifyAll: (callbackName, args...) =>
    for subscription in @subscriptions
      @notify(subscription, callbackName, args...)

  notify: (subscription, callbackName, args...) =>
    if typeof subscription is "string"
      subscriptions = @findAll(subscription)
    else
      subscriptions = [subscription]

    for subscription in subscriptions
      subscription[callbackName]?(args...)

  sendCommand: (subscription, command) =>
    {identifier} = subscription
    @consumer.send({command, identifier})

module.exports = Subscriptions
