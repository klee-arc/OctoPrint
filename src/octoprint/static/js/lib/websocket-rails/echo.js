var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

this.PrinterCommClass = (function() {
  function PrinterCommClass(url, useWebsocket, printer_session_key) {
    this.connectPort = __bind(this.connectPort, this);
    this.destoryPort = __bind(this.destroyPort, this);
    this.statusUpdate = __bind(this.statusUpdate, this);
    this.receiveCommand = __bind(this.receiveCommand, this);
    this.receiveFile = __bind(this.receiveFile, this);
    this.bindEvents = __bind(this.bindEvents, this);
    this.dispatcher = new WebSocketRails(url, useWebsocket);
    this.channel = this.dispatcher.subscribe("printer_session_" + printer_session_key);
    console.log("URL : " + url);
    console.log("SUBSCRIBE : printer_session_" + printer_session_key);
    this.bindEvents();
  }

  PrinterCommClass.prototype.bindEvents = function() {
    this.channel.bind('open_connection', this.connectPort);
    this.channel.bind('close_connection', this.destroyPort);
    this.channel.bind('user_command', this.receiveCommand);
    return this.channel.bind('user_file', this.receiveFile);
  };

  PrinterCommClass.prototype.statusUpdate = function(current_status) {
    return this.dispatcher.trigger('status_update', {
      secret: secret_key,
      status: current_status
    });
  };

  PrinterCommClass.prototype.connectPort = function() {
    return this.dispatcher.trigger('status_update', {
      secret: secret_key,
      status: "horrible"
    });
		post_connection(api_key,message).done(function(data, status, xhr) {
		}).fail(function(xhr, status) {
		}); 
	};

  PrinterCommClass.prototype.destroyPort = function(query) {
		destroy_connection(api_key).done(function(data, status, xhr) {
		}).fail(function(xhr, status) {
		}); 
	};

  PrinterCommClass.prototype.receiveCommand = function(query) {};

  PrinterCommClass.prototype.receiveFile = function(file) {};

  return PrinterCommClass;

})();

function get_connection(key) {
	return $.ajax({
		url: "/api/connection",
		type: "GET",
		dataType: "JSON",
		headers: {"X-ApiKey": key},
		beforeSend: function() {
			console.log("get_connection executed");
		}
	});
}

function get_job(key) {
	return $.ajax({
		url: "/api/job",
		type: "GET",
		dataType: "JSON",
		headers: {"X-ApiKey": key},
		beforeSend: function() {
			console.log("get_job executed");
		}
	});
}

function post_connection(key, cmd) {
	console.log("post_connection")
	return $.ajax({
		url: "/api/connection",
		type: "POST",
		dataType: "JSON",
		headers: {"X-ApiKey": key},
		data: {"command": "connect", "baudrate": cmd["baudrate"], "port": cmd["port"]},
		beforeSend: function() {
			console.log("connecting to printer");
		}
	});
	
}

function destroy_connection(key) {
	return $.ajax({
		url: "/api/connection",
		type: "POST",
		dataType: "JSON",
		headers: {"X-ApiKey": key},
		data: {"command": "disconnect"},
		beforeSend: function() {
			console.log("disconnecting printer");
		}
	});
	
}

function post_job(key, cmd) {
	if (cmd != "start" && cmd != "restart" && cmd != "pause" && cmd != "cancel") {
		return false;
	} else {
		return $.ajax({
			url: "/api/job",
			type: "POST",
			dataType: "JSON",
			headers: {"X-ApiKey": key},
			data: {"command": cmd},
			beforeSend: function() {
				console.log("sending command to printer : "+cmd);
			}
		});
	}
}

function set_status(res, key, status, content) {
	res[key + "_f"] = status;
	res[key] = content;
	return res;
}
