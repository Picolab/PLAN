ruleset html.plan {
  meta {
    provides header, footer
  }
  global {
    pico_logo = "https://raw.githubusercontent.com/Picolab/PLAN/main/docs/pico-logo-transparent-48x48.png"
    user_circle_svg = "https://raw.githubusercontent.com/Picolab/fully-sharded-database/main/images/user-circle-o-white.svg"
    header = function(title,scripts) {
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
</style>
#{scripts.defaultsTo("")}
  </head>
  <body>
    <div id="plan-bar">
      <img class="logo" src="#{pico_logo}" alt="pico logo">
      <a href="/plan.html">
      <span class="plan">Pico Labs Affiliate Network</span>
      </a>
      <img class="user-circle" src="#{user_circle_svg}">
    </div>
    <div style="background-color:white;color:black;height:100%;border-radius:5px">
      <div id="section" style="height:100vh;margin-left:10px">
>>
    }
    footer = function() {
      <<    </div>
    </div>
  </body>
</html>
>>
    }
  }
}
