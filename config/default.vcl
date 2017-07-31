backend web01 {
 .host = "$(eval "echo \$BACKEND_PORT_${BACKEND_ENV_PORT}_TCP_ADDR")";
 .port = "${BACKEND_ENV_PORT}";
 .connect_timeout = 900s;
 .first_byte_timeout = 900s;
 .between_bytes_timeout = 900s;
}
sub vcl_recv {
  set req.backend = web01;

  if (req.http.X-Forwarded-For) {
    set req.http.X-Forwarded-For = req.http.X-Forwarded-For;
  } else {
    set req.http.X-Forwarded-For = regsub(client.ip, ":.*", "");
  }

  if (! req.http.Authorization ~ "Basic anVzdGJ1dGlrOmp1c3RidXRpa2RldnNpdGUyMDE2" && ! req.http.X-Forwarded-For ~ "37.193.113.123" && ! req.http.X-Forwarded-For ~ "5.128.82.23" ) {
           error 401 "Restricted";
  }

  if (req.http.Cookie ~ "justbutikUserGender") {
    set req.http.UserGender = ";" + req.http.Cookie;
    set req.http.UserGender = regsuball(req.http.UserGender, "; +", ";");
    set req.http.UserGender = regsuball(req.http.UserGender, ";(justbutikUserGender)=", "; \1=");
    set req.http.UserGender = regsuball(req.http.UserGender, ";[^ ][^;]*", "");
    set req.http.UserGender = regsuball(req.http.UserGender, "^[; ]+|[; ]+$", "");
    set req.http.UserGender = regsuball(req.http.UserGender, "(justbutikUserGender)=", "");
  }

  if (req.http.Cookie ~ "justbutikUserCurrency") {
    set req.http.UserCurrency = ";" + req.http.Cookie;
    set req.http.UserCurrency = regsuball(req.http.UserCurrency, "; +", ";");
    set req.http.UserCurrency = regsuball(req.http.UserCurrency, ";(justbutikUserCurrency)=", "; \1=");
    set req.http.UserCurrency = regsuball(req.http.UserCurrency, ";[^ ][^;]*", "");
    set req.http.UserCurrency = regsuball(req.http.UserCurrency, "^[; ]+|[; ]+$", "");
    set req.http.UserCurrency = regsuball(req.http.UserCurrency, "(justbutikUserCurrency)=", "");
  }

  if (req.request == "POST") {
    return(pipe);
  }

  if (req.http.x-pipe && req.restarts > 0) {
    return(pipe);
  }
  set req.grace = 120s;
  if (req.request == "PURGE") {
    if (!req.http.X-Wodby-Purge) {
      error 405 "Not allowed.";
    }
    return(lookup);
  }
  if (req.http.X-Wodby-Monitor) {
    return(pass);
  }
  if (req.http.Cookie ~ "justbutikUserIsAdmin") {
    return(pass);
  }
  # Do not cache these paths.
  if (req.url ~ "^/status\.php$" ||
    req.url ~ "^/update\.php$" ||
    req.url ~ "^/admin/*" ||
    req.url ~ "^/user/*" ||
    req.url ~ "^/node/*/sapi-devel" ||
    req.url ~ "^/node/*/edit" ||
    req.url ~ "^/flag/.*$"){

    return(pass);
  }


  if(req.url ~ "\.(msi|exe|dmg|zip|tgz|gz)") {
    return(pipe);
  }
  if (req.request != "GET" && req.request != "HEAD") {
    return(pass);
  }
  if (req.http.Cookie ~ "desktop") {
    set req.http.X-pinned-device = "desktop";
  }
  else if (req.http.Cookie ~ "mobile") {
    set req.http.X-pinned-device = "mobile";
  }
  else if (req.http.Cookie ~ "tablet") {
    set req.http.X-pinned-device = "tablet";
  }
  if (req.url ~ "(?i)/(modules|themes|files)/.*\.(png|gif|jpeg|jpg|ico|css|js|ttf|eot)(\?[a-z0-9]+)?$" && req.url !~ "/system/files") {
    unset req.http.Cookie;
    set req.http.X-static-asset = "True";
  }
  if (req.url ~ "(?i)/(modules|themes|files)/.*\.(doc|docx|xsl|xslx|ppt|pptx)(\?[a-z0-9]+)?$" && req.url !~ "/system/files") {
    unset req.http.Cookie;
    return(pass);
  }
  if(req.url ~ "^/cron.php") {
    return(pass);
  }
  if ((req.http.host ~ "^(www\.|web\.)?ise") &&
     (req.http.User-Agent ~ "(?i)feed")) {
       return(pass);
  }
  if(req.http.cookie ~ "(NO_CACHE|PERSISTENT_LOGIN_[a-zA-Z0-9]+)") {
    return(pass);
  }
  if (req.http.Authorization) {
    return(pass);
  }
  #if(req.http.cookie ~ "(^|;\s*)(S?SESS[a-zA-Z0-9]*)=") {
  #  return(pass);
  #}
  if (req.http.Cookie) {
    set req.http.X-Wodby-Cookie = req.http.cookie;
    unset req.http.Cookie;
  }
  if (req.http.User-Agent ~ "simpletest") {
    return(pipe);
  }

  return(lookup);
}
sub vcl_hash {
  hash_data(req.url);
  if (req.http.host) {
      hash_data(req.http.host);
  } else {
      hash_data(server.ip);
  }
  if (req.http.X-Forwarded-Proto) {
    hash_data(req.http.X-Forwarded-Proto);
  }
  if (req.http.UserGender) {
    hash_data(req.http.UserGender);
  }
  if (req.http.UserCurrency) {
    hash_data(req.http.UserCurrency);
  }

  return (hash);
}
sub vcl_hit {
  if (req.request == "PURGE") {
    purge;
    error 200 "Purged.";
  }
}
sub vcl_miss {
  if (req.http.X-Wodby-Cookie) {
    set bereq.http.Cookie = req.http.X-Wodby-Cookie;
    unset bereq.http.X-Wodby-Cookie;
  }
  if (req.request == "PURGE") {
    purge;
    error 404 "Not in cache.";
  }
}
sub vcl_pass {
  if (req.http.X-Wodby-Cookie) {
    set bereq.http.Cookie = req.http.X-Wodby-Cookie;
    unset bereq.http.X-Wodby-Cookie;
  }
}
sub vcl_pipe {
  set bereq.http.connection = "close";
}
sub vcl_fetch {
#  set beresp.http.X-Wodby-App-Server = beresp.backend.name;
 set beresp.do_esi = true;
  if ( beresp.http.Content-Length ~ "[0-9]{8,}" ) {
     set req.http.x-pipe = "1";
     return(restart);
  }
  if (req.http.X-static-asset) {
    unset beresp.http.Set-Cookie;
  }
  if (beresp.status >= 302 || !(beresp.ttl > 0s) || req.request != "GET") {
    set beresp.http.X-Cacheable = "NO:Not Cacheable";
    call ah_pass;
  }
  if (beresp.status == 301) {
    if (beresp.ttl < 15m) {
      set beresp.ttl = 15m;
    }
  }
  if(beresp.http.Pragma ~ "no-cache" ||
     beresp.http.Cache-Control ~ "no-cache" ||
     beresp.http.Cache-Control ~ "private") {
    set beresp.http.X-Cacheable = "NO:Cache-Control=private";
    call ah_pass;
  }
  if(req.url ~ "^/cron.php") {
    return(hit_for_pass);
  }
  if(beresp.http.Set-Cookie ~ "SESS") {
    set beresp.http.X-Cacheable = "NO:Got Session";
    call ah_pass;
  }
  set beresp.grace = 120s;
  return(deliver);
}
sub vcl_deliver {
set resp.http.X-Gender = req.http.UserGender;
set resp.http.X-Currency = req.http.UserCurrency;
  if (obj.hits > 0) {
    set resp.http.X-Cache = "HIT";
    set resp.http.X-Cache-Hits = obj.hits;
    unset resp.http.Set-Cookie;
  } else {
    set resp.http.X-Cache = "MISS";
  }
  if (req.http.Via ~ "akamai") {
    set resp.http.X-Age = resp.http.Age;
    unset resp.http.Age;
  }
  if (req.http.X-static-asset) {
    unset resp.http.Set-Cookie;
  }
  if (req.http.user-agent ~ "Safari" && !req.http.user-agent ~ "Chrome") {
    set resp.http.cache-control = "max-age: 0";
  }
  if (req.http.user-agent ~ "ELB-HealthChecker") {
    set resp.http.Connection = "close";
  }
  if (resp.http.Cache-Control) {
    unset resp.http.Cache-Control;
  }
  if (resp.http.Not-Cache-Browser == "1") {
    set resp.http.Cache-Control = "no-store, no-cache, must-revalidate, post-check=0, pre-check=0";
    unset resp.http.Not-Cache-Browser;
  }

  return(deliver);
}
sub vcl_error {
set obj.http.Content-Type = "text/html; charset=utf-8";
  if (obj.status == 750) {
    set obj.http.Location = obj.response + req.url;
    set obj.status = 302;
    set obj.response = "Found";
    return(deliver);
  }
  set obj.http.Content-Type = "text/html; charset=utf-8";
  synthetic {"<?xml version="1.0" encoding="utf-8"?>
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
  <html>
    <head>
      <title>"} + obj.status + " " + obj.response + {"</title>
    </head>
    <body>
    <h1>This server is experiencing technical problems. Please
try again in a few moments. Thanks for your continued patience, and
we're sorry for any inconvenience this may cause.</h1>
    <p>Error "} + obj.status + " " + obj.response + {"</p>
    <p>"} + obj.response + {"</p>
      <p>XID: "} + req.xid + {"</p>
    </body>
   </html>
   "};

  if (obj.status == 401) {
    # Prompt for password.
    set obj.http.WWW-Authenticate = "Basic realm=Secured";
  }
  synthetic {"
    <?xml version="1.0" encoding="utf-8"?>
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    <html>
      <head>
        <title>"} + obj.status + " " + obj.response + {"</title>
      </head>
      <body>
        <div id="page">
          <h1>Page Could Not Be Loaded</h1>
          <p>We're very sorry, but the page could not be loaded properly. This should be fixed very soon, and we apologize for any inconvenience.</p>
          <hr />
          <h4>Debug Info:</h4>
            <pre>Status: "} + obj.status + {"
Response: "} + obj.response + {"
XID: "} + req.xid + {"</pre>
        </div>
      </body>
    </html>
  "};
  return(deliver);
}
sub ah_pass {
  set beresp.ttl = 10s;
  return(hit_for_pass);
}
