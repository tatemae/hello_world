class Error < ControllerBase
  
  def self.respond(env, params, headers, ex)
    # Output basic info:
    env.logger.error %{%s - "%s %s%s"} % [
              env['HTTP_X_FORWARDED_FOR'] || env["REMOTE_ADDR"] || "-",
              env["REQUEST_METHOD"],
              env["PATH_INFO"],
              env["QUERY_STRING"].empty? ? "" : "?"+env["QUERY_STRING"]
            ]
    env.logger.error $! # This will dump the exception
    env.logger.error $@ # and full stack trace.
    uri = Globals.proxy_url(env) + env['REQUEST_PATH'] + (env["QUERY_STRING"].empty? ? "" : "?"+env["QUERY_STRING"])
    Toadhopper(env.airbrake_key).post!(ex, {:url => uri, :params => params}) if Goliath.prod?
    [200, {}, error_out(headers, uri)]  
  end
  
  def self.error_out(headers, uri)
    if Goliath.dev?
      %Q{<html>
          <head>
            <title>Error</title>
            <style>
              div{margin:10px;}
              .message{color:#000;}
            </style>
          </head>
          <body>
            <div>An Error Occurred. We're working on the problem...</div>
            <div class="message">
              <div>URI: #{uri}</div>
              <div>Error: #{$!}</div>
              <div>Stack: #{$@.join('<br />') if $@}</div>
              <div>Headers: #{headers}</div>
            </div>
          </body>
        </html>}      
    else  
      %Q{<html>
          <head>
            <title>Error</title>
          </head>
          <body>
            <div style="width:600px;margin:200px auto;font-size:36px;">An Error Occurred. We're working on the problem...</div>
          </body>
        </html>}
    end
  end
  
end