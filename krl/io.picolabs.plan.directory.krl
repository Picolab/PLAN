ruleset io.picolabs.plan.directory {
  meta {
    name "Directories"
    use module io.picolabs.plan.apps alias app
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias subs
    use module io.picolabs.plan.profile alias profile
    shares directory, roster
  }
  global {
    event_domain = "io_picolabs_plan_directory"
    indexes = function(){
      indexes_rid = "io.picolabs.plan.indexes"
      parent_eci = wrangler:parent_eci()
      advertised_indexes =
        wrangler:picoQuery(parent_eci,indexes_rid,"indexes")
      advertised_indexes
    }
    directory = function(_headers){
      join_url = function(s){
        eci = s.get("eci")
        <<#{meta:host}/sky/event/#{meta:eci}/none/#{event_domain}/join_request>>
        + "?wellKnown_Tx=" + eci
      }
      join_link = function(s){
        <<<a href="#{join_url(s)}">join</a> >>
      }
      leave_link = function(s){
        leave_url = join_url(s)
          .replace(re#join_request#,"leave_request")
        <<<a href="#{leave_url}">leave</a> >>
      }
      roster_link = function(s){
        <<<a href="roster.html">roster</a> >>
      }
      app:html_page("Manage Directories", "",
<<
<h1>Manage Directories</h1>
<table>
<tr>
<th>name</th>
<th>wellKnown_Tx</th>
<th>action</th>
<th>member since</th>
<th>roster</th>
</tr>
#{indexes().values().map(function(s){
  wellKnown_Tx = s.get("eci")
  is_member = ent:member_of{wellKnown_Tx}
<<<tr>
<td>#{s.get("name")}</td>
<td>#{wellKnown_Tx}</td>
<td>#{is_member => leave_link(s) | join_link(s)}</td>
<td>#{is_member || "N/A"}</td>
<td>#{is_member => roster_link(s) | "&nbsp;"}</td>
</tr>
>>}).join("")}</table>
>>, _headers)
    }
    roster = function(_headers){
      agg_eci = subs:established("Rx_role","affiliate").head().get("Tx")
      roster_rid = "io.picolabs.plan.roster"
      onclick = function(s){
        << onclick="do_it('#{s}'); void 0">>
      }
      src = wrangler:picoQuery(agg_eci,roster_rid,"roster")
        .replace("wellKnown_Rx","propose relationship")
        .split(re#</?button>#)
        .reduce(
          function(a,s,i){
            r = i%2 == 0 => s
              | ctx:channels.any(function(c){c{"id"}==s}) => "N/A"
              | "<button"+onclick(s)+">"+s+"</button>"
            a + (i%2 => r | s)
          },"")
      app:html_page(
        "Alphabetic List", // title hard-coded
        "<script>function do_it(s){alert(':'+s)}</script>",
        src,
        _headers
      )
    }
  }
  rule joinDirectory {
    select when io_picolabs_plan_directory join_request
      wellKnown_Tx re#(.+)# setting(eci)
    fired {
      raise wrangler event "subscription" attributes {
        "wellKnown_Tx": eci,
        "Rx_role": "affiliate",
        "Tx_role": "affiliate list",
        "name": random:uuid(),
        "channel_type": "alphabetic-list-member",
      }
    }
  }
  rule leaveDirectory {
    select when io_picolabs_plan_directory leave_request
      wellKnown_Tx re#(.+)# setting(wellKnown_Tx)
    pre {
      hard_coded_subs = subs:established("Rx_role","affiliate").head()
      hard_coded_Id = hard_coded_subs.get("Id")
    }
    if hard_coded_Id then noop()
    fired {
      raise wrangler event "subscription_cancellation" attributes
        {"Id":hard_coded_Id}
      ent:member_of{wellKnown_Tx} := null
    }
  }
  rule recordJoining {
    select when wrangler outbound_pending_subscription_approved
      wellKnown_Tx re#(.+)# setting(wellKnown_Tx)
    fired {
      ent:member_of{wellKnown_Tx} := time:now()
    }
  }
  rule redirectBack {
    select when io_picolabs_plan_directory join_request
             or io_picolabs_plan_directory leave_request
    pre {
      url = app:query_url(meta:rid,"directory.html")
    }
    send_directive("_redirect",{"url":url})
  }
  rule sendOverProfileData {
    select when wrangler subscription_added
    pre {
      Id = event:attrs.get("Id")
      aggregator = event:attrs.get(["bus","Tx_role"]).match(re# list$#)
      data = aggregator => profile:data()
        .put("wellKnown_Rx",subs:wellKnown_Rx().get("id")) | null
    }
    if Id && aggregator then event:send({
      "eci":event:attrs.get("Tx"),
      "domain":"io_picolabs_plan_roster",
      "type":"data_provided",
      "attrs":{"Id":Id,"data":data}
    })
  }
}
