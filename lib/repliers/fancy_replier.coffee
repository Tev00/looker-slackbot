_ = require("underscore")

sassyMessages = [

  # Portuguese
  ["br", "Um minutinho"]
  ["br", "Já ta chegando..."]
  ["br", "Coletando os dados"]
  ["br", "Deixa eu ver..."]
  ["br", "Um instante"]
  ["br", "Espere um minuto"]
  ["br", "Um pouco de paciência"]
  ["br", "Give me a minute"]
  ["br", "Vou ver aqui para você"]
  ["br", "Pesquisando..."]
  ["br", "Por favor espere, caro Logger"]
  ["br", "Vamos ver os dados #DataDrivenLoggi"]
  ["br", "Un moment s'il vous plait"]
  ["br", "Wait a moment"]
  ["br", "Hmm"]

].map(([country, message] = pair) ->
  translate = "https://translate.google.com/#auto/auto/#{encodeURIComponent(message)}"
  "<#{translate}|:flag-#{country}:> _#{message}..._"
)

module.exports = class FancyReplier

  constructor: (replyContext) ->
    @replyContext = replyContext

  reply: (obj, cb) ->
    if @loadingMessage

      # Hacky stealth update of message to preserve chat order

      if typeof(obj) == 'string'
        obj = {text: obj, channel: @replyContext.sourceMessage.channel}

      params = {ts: @loadingMessage.ts, channel: @replyContext.sourceMessage.channel}

      update = _.extend(params, obj)
      update.attachments = if update.attachments then JSON.stringify(update.attachments) else null
      update.text = update.text || " "
      update.parse = "none"

      @replyContext.defaultBot.api.chat.update(update)

    else
      @replyContext.replyPublic(obj, cb)

  startLoading: (cb) ->

    # Scheduled messages don't have a loading indicator, why distract everything?
    if @replyContext.scheduled
      cb()
      return

    sass = if @replyContext.isSlashCommand()
      "…"
    else
      sassyMessages[Math.floor(Math.random() * sassyMessages.length)]

    if process.env.DEV == "true"
      sass = "[DEVELOPMENT] #{sass}"

    params =
      text: sass
      as_user: true
      attachments: [] # Override some Botkit stuff
      unfurl_links: false
      unfurl_media: false

    @replyContext.replyPublic(params, (error, response) =>
      @loadingMessage = response
      cb()
    )

  start: ->
    if process.env.LOOKER_SLACKBOT_LOADING_MESSAGES != "false"
      @startLoading(=>
        @work()
      )
    else
      @work()

  replyError: (response) ->
    console.error(response)
    if response?.error
      @reply(":warning: #{response.error}")
    else if response?.message
      @reply(":warning: #{response.message}")
    else
      @reply(":warning: Something unexpected went wrong: #{JSON.stringify(response)}")

  work: ->

    # implement in subclass
