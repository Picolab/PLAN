ruleset io.picolabs.plan.webhook {
  meta {
    name "webhooks"
    use module io.picolabs.plan.apps alias app
    use module io.picolabs.wrangler alias wrangler
    shares webhook
  }
  global {
    styles = <<<style type="text/css">
table {
  border: 1px solid black;
  border-collapse: collapse;
}
td, th {
  border: 1px solid black;
  padding: 5px;
}
</style>
>>
    webhook = function(_headers){
      identifierRE = "[A-Za-z][A-Za-z0-9_]*"
      app:html_page("manage webhooks", styles,
<<
<h1>Manage Webhooks</h1>
<form action="#{app:event_url(meta:rid,"new_webhook")}">
<table>
<tr>
<th>Event domain</th>
<th>Event type</th>
<th>URL</th>
<th>del</th>
</tr>
#{ent:webhooks.values().map(function(w){
  uri = w.get("uri")
  del_url = app:event_url(meta:rid,"webhook_not_needed")
          + "?event_domain=" + w.get("domain")
          + "&event_type=" + w.get("type")
  <<<tr>
<td>#{w.get("domain")}</td>
<td>#{w.get("type")}</td>
<td><a href="#{uri}" target="_blank" title="#{uri}">webhook</a></td>
<td><a href="#{del_url}">del</a></td>
</tr>
>>}).join("")}
<tr>
<td><input name="event_domain" required pattern="#{identifierRE}" title="identifier"></td>
<td><input name="event_type" required pattern="#{identifierRE}" title="identifier"></td>
<td colspan="2"><button type="submit">Add</button></td>
</tr>
</table>
</form>
>>, _headers)
    }
  }
  rule initialize {
    select when io_picolabs_plan_webhook factory_reset
      where ent:webhooks.isnull()
    fired {
      ent:webhooks := {}
    }
  }
  rule addNewWebhook {
    select when io_picolabs_plan_webhook new_webhook
      event_domain re#([A-Za-z][A-Za-z0-9_]*)#
      event_type   re#([A-Za-z][A-Za-z0-9_]*)#
      setting(event_domain,event_type)
    pre {
      event_designation = event_domain + ":" + event_type
      channel_tags = ["webhook",event_designation]
      already_assigned = ent:webhooks >< event_designation
    }
    if not already_assigned then
      wrangler:createChannel(
        channel_tags,
        {"allow":[{"domain":event_domain,"name":event_type}],"deny":[]},
        {"allow":[],"deny":[{"rid":"*","name":"*"}]}
      ) setting(chan)
    fired {
      ent:webhooks{event_designation} := {
        "domain":event_domain,
        "type":event_type,
        "uri":meta:host+"/sky/event/"+chan.get("id")+"/none/"+event_domain+"/"+event_type
      }
    }
  }
  rule removeWebhook {
    select when io_picolabs_plan_webhook webhook_not_needed
      event_domain re#([A-Za-z][A-Za-z0-9_]*)#
      event_type   re#([A-Za-z][A-Za-z0-9_]*)#
      setting(event_domain,event_type)
    pre {
      event_designation = event_domain + ":" + event_type
      webhook = ent:webhooks.get(event_designation)
      eciRE = re#/sky/event/([^/]*)/#
      eci = webhook.get("uri").extract(eciRE).head()
    }
    if eci then wrangler:deleteChannel(eci)
    fired {
      clear ent:webhooks{event_designation}
    }
  }
  rule refresh {
    select when io_picolabs_plan_webhook new_webhook
             or io_picolabs_plan_webhook webhook_not_needed
    pre {
      home_page = app:query_url(meta:rid,"webhook.html")
    }
    send_directive("_redirect",{"url":home_page})
  }
}
