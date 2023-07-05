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
      tags = ent:apps{[rid,"tags"]}
      wrangler:channels(tags).reverse().head().get("id")
    }
    evd_for_rid = function(rid){
      rid.replace(re#[.-]#g,"_")
    }
    event_url = function(rid,event_type,event_id){
      eci = eci_for_rid(rid)
      eid = event_id || "none"
      event_domain = evd_for_rid(rid)
      <<#{meta:host}/sky/event/#{eci}/#{eid}/#{event_domain}/#{event_type}>>
    }
    query_url = function(rid,query_name){
      eci = eci_for_rid(rid)
      <<#{meta:host}/c/#{eci}/query/#{rid}/#{query_name}>>
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
      home_url = query_url(rid,app.get("home_url"))
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
<input class="wide90" name="config" value="{}">
<br>
<button type="submit">Install</button>
</form>
>>
      + html:footer()
    }
  }
  rule initializeBaseCase {
    select when wrangler ruleset_installed
          where event:attr("rids") >< meta:rid && ent:apps.isnull()
    fired {
      ent:apps := {}
      raise io_picolabs_plan_apps event "new_apps_app" attributes event:attrs
    }
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
             or io_picolabs_plan_apps new_apps_app
    foreach event:attr("rids") setting(rid)
    pre {
      rsMeta = wrangler:rulesetMeta(rid)
      home_url = rsMeta.get("shares").head() + ".html"
      rsname = rsMeta.get("name")
      rsnameForChannelTag = rsname.lc().replace(re#  *#g,"-")
      channel_tags = ["app"].append(rsnameForChannelTag)
      spec = {
        "home_url":home_url,
        "rid":rid,
        "rsname":rsname,
        "tags":channel_tags
      }
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
      raise io_picolabs_plan_apps event "app_installed" attributes spec
      raise event ev_domain+":factory_reset" for rid.klog("factory_reset")
    }
  }
  rule keepAppChannelsClean {
    select when io_picolabs_plan_apps app_installed
    foreach wrangler:channels(event:attr("tags")).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
  rule getModuleInstalled {
    select when io_picolabs_plan_apps module_needed
      url re#(.+)#
      config re#(.*)#
      setting(url,config)
    fired {
      raise wrangler event "install_ruleset_request" attributes
        event:attrs.put("config",config.decode())
    }
  }
  rule redirectBack {
    select when io_picolabs_plan_apps app_installed
             or io_picolabs_plan_apps module_needed
             or io_picolabs_plan_apps app_deleted
    send_directive("_redirect",{"url":query_url(meta:rid,"apps.html")})
  }
  rule deleteApp {
    select when io_picolabs_plan_apps app_unwanted
      rid re#(.+)#
    fired {
      // delay one evaluation cycle
      raise explicit event "app_unwanted" attributes event:attrs
    }
  }
  rule actuallyDeleteApp {
    select when explicit app_unwanted
      rid re#(.+)# setting(rid)
    pre {
      permanent = meta:rid == rid
    }
    if not permanent then noop()
    fired {
      raise wrangler event "uninstall_ruleset_request" attributes event:attrs.put("tx",meta:txnId)
    }
  }
  rule updateApps {
    select when wrangler:ruleset_uninstalled where event:attr("tx") == meta:txnId
    pre {
      rid = event:attr("rid")
    }
    fired {
      clear ent:apps{rid}
      raise io_picolabs_plan_apps event "app_deleted" attributes event:attrs
    }
  }
}
