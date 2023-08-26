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
        inactive = profile:data().get("name").isnull()
                   || s.get("name") == "Bazaar of Applications"
        msg = "Set your profile name before joining"
        disabled = inactive => << disabled title="#{msg}">> | ""
        <<<a href="#{join_url(s)}"#{disabled}>join</a> >>
      }
      leave_link = function(s){
        leave_url = join_url(s)
          .replace(re#join_request#,"leave_request")
        <<<a href="#{leave_url}">leave</a> >>
      }
      roster_link = function(s){
        <<<a href="roster.html">roster</a> >>
      }
      styles = <<<style type="text/css">
  a[disabled] {
    pointer-events: none;
    text-decoration: none;
    color: inherit;
  }
</style>
>>
      app:html_page(
        "Manage Directories",
        styles,
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
>>,
        _headers)
    }
    roster = function(_headers){
      agg_eci = subs:established("Rx_role","affiliate").head().get("Tx")
      roster_rid = "io.picolabs.plan.roster"
      onclick = function(s){
        << onclick="do_it(this); void 0">>
      }
      base_url = app:event_url(meta:rid,"relationship_proposed")
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
        roster_script(base_url),
        src,
        _headers
      )
    }
    roster_script = function(base_url){
      <<<script type="text/javascript">
function do_it(b){
  Rx_role = prompt("Your role in the proposed relationship?")
  Tx_role = prompt("Their role in the proposed relationship?")
  location = '#{base_url}'
           + '?wellKnown_Tx='+b.innerText
           + '&Rx_role='+Rx_role
           + '&Tx_role='+Tx_role
           + '&Tx_name='+b.parentElement.parentElement.children[0].innerText
}
</script>
>>
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
  rule proposeRelationship {
    select when io_picolabs_plan_directory relationship_proposed
      Rx_role re#(.+)#
      Tx_role re#(.+)#
      wellKnown_Tx re#(.+)#
      Tx_name re#(.+)#
      setting(Rx_role,Tx_role,wellKnown_Tx,Tx_name)
    pre {
      channel_name = wellKnown_Tx + "-" + ctx:channels.head().get("id")
      channel_type = "relationship"
    }
    fired {
      raise wrangler event "subscription" attributes {
        "wellKnown_Tx": wellKnown_Tx,
        "Rx_role": Rx_role, "Tx_role": Tx_role,
        "name": channel_name, "channel_type": channel_type,
        "Tx_name": Tx_name, "Rx_name": profile:data().get("name"),
      }
    }
  }
  rule redirectBack {
    select when io_picolabs_plan_directory join_request
             or io_picolabs_plan_directory leave_request
             or io_picolabs_plan_directory relationship_proposed
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
