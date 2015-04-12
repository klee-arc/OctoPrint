class @PrinterCommClass
  constructor: (url, websocket_url, fabrica_id, octoprint_key) -> 
    @session_key = octoprint_key
    @dispatcher = new WebSocketRails(url, websocket_url)
    @auth_channel = @dispatcher.subscribe("request_token_" + fabrica_id)
    @auth_channel.bind 'oauth_callback', @initBind
    @sendOauthRequest(fabrica_id)

  initBind: (key) =>
    @auth_key = key
    @channel = @dispatcher.subscribe("printer_session_" + @auth_key)
    @bindEvents()

  bindEvents: () =>
    # @channel.bind 'request_status', @statusUpdate
    @channel.bind 'user_command', @userCommand
    @channel.bind 'user_file', @sendFile
    @channel.bind 'machine_refresh', @execRefresh


# Abstract Ajax

  execAjax: (url, type, data=null, content_type="application/json") =>
    $.ajax
      url: url
      type: type
      dataType: "JSON"
      contentType: content_type
      headers:
        "X-ApiKey": @session_key
      data: data

# Oauth

  sendOauthRequest: (fabrica_id) =>
    @dispatcher.trigger "box.oauth_request",
      session_id: fabrica_id
    console.log "send oauth done!"

# Status update

  statusUpdate: (message) =>
    res_code = undefined
    self = @
    $.when(@execAjax("/api/connection","GET"), @execAjax("/api/job","GET"), @execAjax("/api/files","GET")).then((connection, job, files) ->
      res_code = 
        "connection" : connection[0]
        "job" : job[0]
        "files" : files[0]
      self.sendStatusUpdate res_code
      return
    , (connection, job, files) ->
      res_code = 
        "connection" : connection[0]
        "job" : job[0]
        "files" : files[0]
      self.sendStatusUpdate res_code
      console.log "statusUpdate failed!"
      console.log res_code
      return
    )

  sendStatusUpdate: (response) =>
    @dispatcher.trigger "box.status_update",
      token: @auth_key
      status: response
    console.log "status update done!"
    console.log response


# User command and response

  userCommand: (message) =>
    console.log message
    res_code = undefined
    self = @
    $.when(@execAjax(message["url"], message["type"], message["params"])).then((response) ->
      res_code = response
      self.sendCommandResponse res_code
      return
    ,(response) ->
      res_code = response
      self.sendCommandResponse res_code
      return
    )

  sendCommandResponse: (response) =>
    @dispatcher.trigger "box.command_response",
      token: @auth_key
      callback: response


# File transfer

  sendFile: (message) =>
    console.log("dump file")
    console.log(message)

    boundary_key = randomString(16)

    filename = message["filename"]
    content = message["content"]
    content_type = 'multipart/form-data; boundary=----WebKitFormBoundary' + boundary_key

    data = '------WebKitFormBoundary'+boundary_key+' \n'
    data += 'Content-Disposition: form-data; name="file"; filename="'+filename+'" \n'
    data += 'Content-Type: application/octet-stream \n'
    data += content+' \n'
    data += '\n------WebKitFormBoundary'+boundary_key+' \n'
    if message["select"]
      data += 'Content-Disposition: form-data; name="select"\n\ntrue'
    else
      data += 'Content-Disposition: form-data; name="select"\n\nfalse'
    data += '\n------WebKitFormBoundary'+boundary_key+' \n'
    if message["print"]
      data += 'Content-Disposition: form-data; name="print"\n\ntrue'
    else
      data += 'Content-Disposition: form-data; name="print"\n\nfalse'
    data += '\n------WebKitFormBoundary'+boundary_key+'--';

    console.log data

    $.when(@execAjax("/api/files/local", "POST", data, content_type)).then((response) ->
      res_code = response
      self.sendCommandResponse res_code
      return
    ,(response) ->
      res_code = response
      self.sendCommandResponse res_code
      return
    )


# Utilities

  execRefresh: () =>
    location.reload()
