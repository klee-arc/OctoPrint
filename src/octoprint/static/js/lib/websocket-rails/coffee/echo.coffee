#		destroy_connection(api_key).done(function(data, status, xhr) {
#    }).fail(function(xhr, status) {
#    }); 
#    

class @PrinterCommClass
	constructor: (url, useWebsocket, printer_session_key) ->
    @dispatcher = new WebSocketRails(url, useWebsocket)
    @channel = @dispatcher.subscribe("printer_session_" + printer_session_key)
		@bindEvents()

	bindEvents: () =>
		@channel.bind 'open_connection', @connectPort
		@channel.bind 'close_connection', @destroyPort
		@channel.bind 'request_status', @statusUpdate
		@channel.bind 'user_command', @receiveCommand
		@channel.bind 'user_file', @receiveFile

  sendStatus: (current_status) =>
    @dispatcher.trigger "new_status",
      secret: secret_key
      status: current_status

	statusUpdate: (event) =>
    res_code =
      get_connection_f: null
      get_connection: null
      get_job_f: null
      get_job: null
    self = this

    $.when(get_connection(api_key), get_job(api_key)).then((data0, data1) ->
      res_code = set_status(res_code, "get_connection", true, data0[0])
      res_code = set_status(res_code, "get_job", true, data1[0])
      res_code
    , (data0, data1) ->
      res_code = set_status(res_code, "get_connection", false, data0[0])
      res_code = set_status(res_code, "get_job", false, data1[0])
      res_code
    ).then (callback) ->
      self.sendStatus callback
      return

    return

  connectPort: (message) =>
    post_connection(api_key, message).done((data, status, xhr) ->
    ).fail (xhr, status) ->

    return

  destroyPort: (message) =>
    console.log "DESTROY!!!!"





get_connection = (key) ->
  $.ajax
    url: "/api/connection"
    type: "GET"
    dataType: "JSON"
    headers:
      "X-ApiKey": key

    beforeSend: ->
      console.log "get_connection executed"
      return

post_connection = (key, cmd) ->
  console.log cmd
  data_content = JSON.stringify(
    command: "connect"
    baudrate: Number(cmd.baudrate)
    port: cmd.port
    autoconnect: Boolean(cmd.auto)
    save: Boolean(cmd.save)
  )
  $.ajax
    url: "/api/connection"
    type: "POST"
    contentType: "application/json"
    dataType: "JSON"
    data: data_content
    headers:
      "X-ApiKey": key

    beforeSend: ->
      console.log "connecting to printer"
      return

destroy_connection = (key) ->
  $.ajax
    url: "/api/connection"
    type: "POST"
    dataType: "JSON"
    headers:
      "X-ApiKey": key

    data:
      command: "disconnect"

    beforeSend: ->
      console.log "disconnecting printer"
      return

get_job = (key) ->
  $.ajax
    url: "/api/job"
    type: "GET"
    dataType: "JSON"
    headers:
      "X-ApiKey": key

    beforeSend: ->
      console.log "get_job executed"
      return

post_job = (key, cmd) ->
  if cmd isnt "start" and cmd isnt "restart" and cmd isnt "pause" and cmd isnt "cancel"
    false
  else
    $.ajax
      url: "/api/job"
      type: "POST"
      dataType: "JSON"
      headers:
        "X-ApiKey": key

      data:
        command: cmd

      beforeSend: ->
        console.log "sending command to printer : " + cmd
        return

set_status = (res, key, status, content) ->
  res[key + "_f"] = status
  res[key] = content
  res
