ruleset io.picolabs.plan.relate.krl {
  meta {
    name "Relationships"
    use module io.picolabs.subscription alias subs
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.plan.apps alias app
    shares relate
  }
  global {
    wranglerRID = "io.picolabs.wrangler"
    render = function(list,type,canDelete=true,canAccept=false){
      renderRel = function(rel){
        Rx = rel.get("Rx")
        Id = rel.get("Id")
        hideBookkeepingRel = rel.get("Rx_role") == "affiliate"
          && rel.get("Tx_role") == "affiliate list"
        displayName = function(eci){
          thisPico = ctx:channels.any(function(c){c{"id"}==eci})
          eci.isnull() => (Rx.isnull() =>"unknown" | "someone") |
          thisPico     => "you" | ent:names.get([Id,"Tx_name"])
        }
        dmap = {
          "outb":{"eid":"cancel-outbound",
                  "type":"outbound_cancellation",
                  "text":"delete",
                  "msg":"that you have proposed"},
          "estb":{"eid":"delete-subscription",
                  "type":"subscription_cancellation",
                  "text":"delete",
                  "msg":"that you have established"},
          "inbd":{"eid":"reject-inbound",
                  "type":"inbound_rejection",
                  "text":"decline",
                  "msg":"that was proposed by another affiliate"},
        }
        del_link = <<<a href="#{
          meta:host}/sky/event/#{
          Rx}/#{
          dmap{[type,"eid"]}}/wrangler/#{
          dmap{[type,"type"]}}?Id=#{
          rel.get("Id")}" onclick="return confirm('If you proceed you will #{
          dmap{[type,"text"]}} this relationship #{
          dmap{[type,"msg"]}}. This cannot be undone.')">#{
          dmap{[type,"text"]}}</a> >>
        hideBookkeepingRel => "" |
        <<<li><span style="display:none">#{rel.encode()}</span>
#{displayName(Rx).capitalize()} as #{rel.get("Rx_role")} and
#{displayName(rel.get("Tx"))} as #{rel.get("Tx_role")}
#{canAccept => <<<a href="#{meta:host}/sky/event/#{Rx}/accept-inbound/wrangler/pending_subscription_approval?Id=#{rel.get("Id")}">accept</a> >> | ""}
#{canDelete => del_link | ""}
</li>
>>
      }
      the_li = list.map(renderRel).join("")
      <<<ul>
>>
      + (the_li => the_li | "none")
      + <<</ul>
>>
    }
    relate = function(_headers){
      app:html_page("manage Relationships", "",
<<
<h1>Manage Relationships</h1>
<h2>Relationships that are fully established</h2>
#{render(subs:established(),"estb")}
<h2>Relationships that you have proposed</h2>
#{render(subs:outbound(),"outb")}
<h2>Relationships that others have proposed</h2>
#{render(subs:inbound(),"inbd",canAccept=true)}
>>, _headers)
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        ["relationships"],
        {"allow":[{"domain":"io_picolabs_plan_relate_krl","name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
    }
    fired {
      ent:names := {} if ent:names.isnull()
      raise io_picolabs_plan_relate_krl event "channel_created" attributes event:attrs
    }
  }
  rule keepChannelsClean {
    select when io_picolabs_plan_relate_krl channel_created
    foreach wrangler:channels(["relationships"]).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
  rule redirectBack {
    select when wrangler subscription_removed
             or wrangler outbound_subscription_cancelled
             or wrangler subscription_added
             or wrangler inbound_subscription_cancelled
    pre {
      referer = event:attr("_headers").get("referer")
    }
    if referer then send_directive("_redirect",{"url":referer})
  }
  rule wePropose {
    select when wrangler outbound_pending_subscription_added
      Id re#(.+)# setting(Id)
    pre {
      names = {
        "Rx_name": event:attrs.get("Rx_name"),
        "Tx_name": event:attrs.get("Tx_name"),
      }
    }
    fired {
      ent:names{Id} := names
    }
  }
/*
 * Notable events
 */
  rule theyDenyMyProposal {
    select when wrangler outbound_subscription_cancelled
      Id re#(.+)# setting(Id)
    fired {
      ent:names{Id} := null
    }
  }
  rule theyAcceptMyProposal {
    select when wrangler outbound_pending_subscription_approved
  }
  rule theyDeleteEstablished {
    select when wrangler subscription_removed
      Id re#(.+)# setting(Id)
    fired {
      ent:names{Id} := null
    }
  }
  rule theyPropose {
    select when wrangler inbound_pending_subscription_added
      Id re#(.+)# setting(Id)
    pre {
      names = {
        "Rx_name": event:attrs.get("Tx_name"), //change perspective
        "Tx_name": event:attrs.get("Rx_name"), //change perspective
      }
.klog("names")
    }
    fired {
      ent:names{Id} := names
    }
  }
  rule theyDeleteProposal {
    select when wrangler inbound_subscription_cancelled
      Id re#(.+)# setting(Id)
    fired {
      ent:names{Id} := null
    }
  }
}
