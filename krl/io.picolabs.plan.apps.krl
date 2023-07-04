ruleset io.picolabs.plan.apps {
  meta {
    name "applications"
    use module io.picolabs.wrangler alias wrangler
    use module html.plan alias html
    shares apps
    provides event_url, query_url, html_page
  }
  global {
    eci_for_rid = function(rid){
      rsname = wrangler:rulesetMeta(rid).get("name")
      tags = ["app"].append(rsname.lc().replace(re#  *#g,"-"))
      wrangler:channels(tags).reverse().head().get("id")
    }
    evd_for_rid = function(rid){
      rid.replace(re#[.-]#g,"_")
    }
    event_url = function(rid,event_type,event_id){
      eid = event_id || "none"
      <<#{meta:host}/sky/event/#{eci_for_rid(rid)}/#{eid}/#{evd_for_rid(rid)}/#{event_type}>>
    }
    query_url = function(rid,query_name){
      <<#{meta:host}/c/#{eci_for_rid(rid)}/query/#{rid}/#{query_name}>>
    }
    html_page = function(title,head,body,_headers){
      html:header(title,head,_headers)
      + body
      + html:footer()
    }
    ruleset = function(rid){
      ctx:rulesets.filter(function(rs){rs{"rid"}==rid}).head()
    }
    display_app = function(app){
      rsname = app.get("rsname")
      rid = app.get("rid")
      home_url = query_url(rid,app.get("name"))
      url = ruleset(rid).get("url")
      del_url = event_url(meta:rid,"app_unwanted")
      link_to_delete = <<<a href="#{del_url}?rid=#{rid}" onclick="return confirm('This cannot be undone, and #{rsname} may be lost if you proceed.')">del</a> >>
      <<<tr>
<td>#{rid}</td>
<td><a href="#{home_url}">Manage #{rsname}</a></td>
<td>#{url}</td>
<td>#{meta:rid == rid => "N/A" | link_to_delete}</td>
</tr>
>>
    }
    styles = <<<style type="text/css">
table {
  border: 1px solid black;
  border-collapse: collapse;
}
td, th {
  border: 1px solid black;
  padding: 5px;
}
input.wide90 {
  width: 90%;
}
</style>
>>
    apps = function(_headers){
      html:header("manage applications",styles,_headers)
      + <<
<h1>Manage applications</h1>
<h2>Applications</h2>
<form method="POST" action="#{event_url(meta:rid,"new_app")}">
<table>
<tr>
<th>RID</th>
<th>Home page</th>
<th>Ruleset URI</th>
<th>Delete</th>
</tr>
#{ent:apps.values().map(display_app).join("")}
<tr>
<td colspan="2">Add an app by URL:</td>
<td colspan="2">
<input class="wide90" type="text" name="url" placeholder="app URL">
<button type="submit">Add</button>
</td>
</tr>
</table>
</form>
<h2>Technical</h2>
<p>If your app needs a module, install it here first:</p>
<form action="#{event_url(meta:rid,"module_needed")}">
<input class="wide90" name="url" placeholder="module URL">
<br>
<input class="wide90" name="config" placeholder="{}">
<br>
<button type="submit">Install</button>
</form>
>>
      + html:footer()
    }
  }
  rule initializeBaseCase {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        ["app","applications"],
        {"allow":[{"domain":"io_picolabs_plan_apps","name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
    }
    fired {
      raise io_picolabs_plan_apps event "factory_reset"
    }
  }
  rule keepChannelsClean {
    select when io_picolabs_plan_apps factory_reset
    foreach wrangler:channels(["app","applications"]).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
  rule installApp {
    select when io_picolabs_plan_apps new_app
      url re#(.+)# setting(url)
    fired {
      raise wrangler event "install_ruleset_request"
        attributes event:attrs.put({"url":url,"tx":meta:txnId})
    }
  }
  rule makeInstalledRulesetAnApp {
    select when wrangler ruleset_installed where event:attr("tx") == meta:txnId
    foreach event:attr("rids") setting(rid)
    pre {
      rsMeta = wrangler:rulesetMeta(rid)
      home = rsMeta.get("shares").head() + ".html"
      rsname = rsMeta.get("name")
      spec = {"name":home,"status":"installed","rid":rid,"rsname":rsname}
      channel_tags = ["app"].append(rsname.lc().replace(re#  *#g,"-"))
      ev_domain = evd_for_rid(rid)
    }
    every {
      wrangler:createChannel(
        channel_tags,
        {"allow":[{"domain":ev_domain,"name":"*"}],"deny":[]},
        {"allow":[{"rid":rid,"name":"*"}],"deny":[]}
      )
    }
    fired {
      ent:apps{rid} := spec
      raise io_picolabs_plan_apps event "app_installed" attributes spec.put("tags",channel_tags)
      raise event ev_domain+":factory_reset" for rid.klog("factory_reset")
    }
  }
  rule keepAppChannelsClean {
    select when io_picolabs_plan_apps app_installed
    foreach wrangler:channels(event:attr("tags")).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
  rule redirectBack {
    select when io_picolabs_plan_apps app_installed
    send_directive("_redirect",{"url":query_url(meta:rid,"apps.html")})
  }
}
