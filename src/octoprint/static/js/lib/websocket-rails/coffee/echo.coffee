class @PrinterCommClass
  constructor: (url, useWebsocket, printer_session_key) ->
    @dispatcher = new WebSocketRails(url, useWebsocket)
    @channel = @dispatcher.subscribe("printer_session_" + printer_session_key)
    @session_key = printer_session_key
    @bindEvents()

  bindEvents: () =>
    @channel.bind 'request_status', @statusUpdate
    @channel.bind 'user_command_receive', @userCommandReceive
    @channel.bind 'user_file', @receiveFile

 #   @dispatcher.bind 'set_session_key', @initialEvent
 # initialEvent: (message) =>
 #   console.log "key set"
 #   window.session_key = message

  receiveFile: (file) =>
    boundary_key = randomString(16)

    filename = file["filename"]
    content = file["content"]
    header = 'multipart/form-data; boundary=----WebKitFormBoundary' + boundary_key

    data = '------WebKitFormBoundary'+boundary_key+' \n'
    data += 'Content-Disposition: form-data; name="file"; filename="'+filename+'" \n'
    data += 'Content-Type: application/octet-stream \n'
    data += content+' \n'
    data += '\n------WebKitFormBoundary'+boundary_key+' \n'
    data += 'Content-Disposition: form-data; name="select" \ntrue \n'
    data += '\n------WebKitFormBoundary'+boundary_key+' \n'
    data += 'Content-Disposition: form-data; name="print" \n'
    data += 'true \n'
    data += '\n------WebKitFormBoundary'+boundary_key+'--';
    console.log data
    $.ajax
      url: "/api/files/local"
      type: "POST"
      headers:
        "X-ApiKey": @session_key
      processData: false
      contentType: header
      data: data
      # contentType: header

  statusUpdate: (message) =>
    res_code = undefined

    self = @
    $.when(@statusReceive("/api/connection"), @statusReceive("/api/job"), @statusReceive("/api/files")).then((connection, job, files) ->
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

  statusReceive: (url) =>
    $.ajax
      url: url
      type: "GET"
      dataType: "JSON"
      headers:
        "X-ApiKey": @session_key

  userCommandReceive: (message) =>
    console.log message
    res_code = undefined
    self = @
    $.when(
      $.ajax
        url: message["url"]
        type: message["type"]
        contentType: "application/json"
        headers:
          "X-ApiKey": @session_key
        data: message["params"]
    ).then((response) ->
      res_code =
        "status" : response["status"]
        "statusText" : response["statusText"]
        "responseText" : response["responseText"]
      self.sendCommandResponse res_code
      return
    ,(response) ->
      res_code =
        "status" : response["status"]
        "statusText" : response["statusText"]
        "responseText" : response["responseText"]
      self.sendCommandResponse res_code
      return
    )

  sendStatusUpdate: (response) =>
    @dispatcher.trigger "status_update",
      secret: @session_key
      status: response
    console.log "status update done!"
    console.log response

  sendCommandResponse: (response) =>
    @dispatcher.trigger "command_response",
      secret: @session_key
      status: response
