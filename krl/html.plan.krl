ruleset html.plan {
  meta {
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.pds alias pds
    provides header, footer, cookies, session_valid
  }
  global {
    session_valid = function(_headers){
      the_cookies = cookies(_headers)
      self_tags = ["self","system"]
      the_name = wrangler:channels(self_tags).reverse().head().get("id")
      the_sid = the_name => the_cookies.get(the_name) | null
      ent:client_secret == the_sid
    }
    pico_logo = "https://raw.githubusercontent.com/Picolab/PLAN/main/docs/pico-logo-transparent-48x48.png"
    user_circle_svg = "https://raw.githubusercontent.com/Picolab/fully-sharded-database/main/images/user-circle-o-white.svg"
    app_url = function(app_tag,app_rid,app_page){
      app_tags = ["app"].append(app_tag)
      eci = wrangler:channels(app_tags).reverse().head().get("id")
      eci => <<#{meta:host}/c/#{eci}/query/#{app_rid}/#{app_page}>> | null
    }
    header = function(title,scripts,_headers) {
      sanity = session_valid(_headers)
      pico_name = wrangler:name()
      is_affiliates = pico_name == "Affiliates"
      sanity_mark = sanity || is_affiliates => "" | << style="color:red">>
      display_name = is_affiliates => pico_name |
        pds:getData(["profile","Your name"]) || pico_name
      plan_url = "https://picolab.github.io/PLAN/"
      landing_url = app_url("applications","io.picolabs.plan.apps","apps.html")
      profile_url = app_url("contact-information","io.picolabs.plan.profile","profile.html")
      <<<!DOCTYPE HTML>
<html>
  <head>
    <title>#{title}</title>
    <meta charset="UTF-8">
    <link rel="shortcut icon" type="image/png" href="#{pico_logo}" />
<style type="text/css">
body {
  min-height: 100vh;
  font-family: "Helvetica Neue",Helvetica,Arial,sans-serif;
  background:linear-gradient(black,white);color:white;
}
#plan-bar {
  height: 48px;
  margin-bottom: -18px;
}
#plan-bar img {
  padding: 12px;
  vertical-align: middle;
}
#plan-bar img.logo {
  border-right: solid 1px #0057b8;
  width: 24px;
  height: 24px;
}
#plan-bar img.user-circle {
  float:right;
}
#plan-bar .plan {
  color:#51b6e5;
  vertical-align: middle;
  font-size: 24px;
  padding-left: 20px;
}
#plan-bar a {
  text-decoration: none;
}
#plan-bar .username {
  float: right;
  color: white;
  vertical-align: middle;
  margin: 15px 10px 0 0;
}
</style>
#{scripts.defaultsTo("")}
  </head>
  <body>
    <div id="plan-bar">
      <a href="#{plan_url}">
      <img class="logo" src="#{pico_logo}" alt="pico logo">
      </a>
      <a href="#{landing_url || "#"}">
      <span class="plan">Pico Labs Affiliate Network</span>
      </a>
      <a href="#{profile_url || "#"}">
      <img class="user-circle" src="#{user_circle_svg}">
      <span class="username"#{sanity_mark}>#{display_name}</span>
      </a>
    </div>
    <div style="background-color:white;color:black;height:100%;border-radius:5px">
      <div id="section" style="min-height:100vh;margin-left:10px">
>>
    }
    footer = function() {
      <<    </div>
    </div>
  </body>
</html>
>>
    }
    cookies = function(_headers) {
      arg = event:attr("_headers") || _headers
      arg{"cookie"}.isnull() => {} |
      arg{"cookie"}
        .split("; ")
        .map(function(v){v.split("=")})
        .collect(function(v){v.head()})
        .map(function(v){v.head()[1]})
    }
    tags = ["client","secret"]
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        tags,
        {"allow":[{"domain":"client","name":"*"}],"deny":[]},
        {"allow":[],"deny":[{"rid":"*","name":"*"}]}
      )
    }
    fired {
      raise html_plan event "channel_created"
    }
  }
  rule keepChannelsClean {
    select when html_plan channel_created
    foreach wrangler:channels(tags).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan{"id"})
  }
  rule rotateClientSecret {
    select when client secret_expired
    pre {
      sid = random:uuid()
      self_tags = ["self","system"]
      the_name = wrangler:channels(self_tags).reverse().head().get("id")
    }
    send_directive("_cookie",{"cookie":<<#{the_name}=#{sid}; Path=/>>})
    fired {
      ent:client_secret := sid
    }
  }
  rule redirectHome {
    select when client secret_expired
    pre {
      landing_url = app_url("applications","io.picolabs.plan.apps","apps.html")
    }
    if landing_url then send_directive("_redirect",{"url":landing_url})
  }
  rule forgetAffiliate {
    select when io_picolabs_plan_apps affiliate_opts_out
    pre {
      self_tags = ["self","system"]
      the_name = wrangler:channels(self_tags).reverse().head().get("id")
    }
    send_directive("_cookie",{"cookie":<<#{the_name}=; Path=/; Max-Age=0>>})
    fired {
      clear ent:client_secret
    }
  }
}
