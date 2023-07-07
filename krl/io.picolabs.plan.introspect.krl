ruleset io.picolabs.plan.introspect {
  meta {
    name "introspections"
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias subs
    use module io.picolabs.plan.apps alias app
    shares introspect, channels, channel//,  subscriptions, subscription TODO
  }
  global {
    rsRID = "io.picolabs.plan.ruleset"
    introspect = function(_headers){
      netid = wrangler:name()
      repo_name = netid + "/bazaar"
      subs_count = subs:established()
        .filter(function(s){s{"Tx_role"}!="participant list"})
        .length()
      pECI = wrangler:parent_eci()
      pName = pECI.isnull() => null | wrangler:picoQuery(pECI,"io.picolabs.wrangler","name")
      apps = app:app_list()
      apps_link = <<<a href="#{app:query_url("io.picolabs.plan.apps","apps.html")}">apps.html</a\>>>
      rs_link = <<<a href="../io.picolabs.plan.ruleset/rulesets.html">rulesets</a\>>>
      cs_link = <<<a href="channels.html">channels</a\>>>
      ss_link = <<#{subs_count} <a href="subscriptions.html">subscription#{subs_count==1 => "" | "s"}</a\>>>
      child_count = wrangler:children().length()
      one_child = child_count==1 => wrangler:children().head() | false
      child_eci = child_count==1 && one_child{"eci"}
      repo_pico = child_count==1 && one_child{"name"}==repo_name
      app:html_page("manage introspections","",
      <<
<h1>Manage introspections</h1>
<h2>Overview</h2>
<p>Your pico is named "#{netid}"#{
  pName => << and its parent pico is named "#{pName}".>> | "."}</p>
<p>It has #{wrangler:installedRIDs().length()} #{rs_link},
of which #{apps.length()} are apps.
The apps can be managed with #{apps_link}.</p>
<p>It has #{wrangler:channels().length()} #{cs_link}.</p>
<p>It has #{subs_count => ss_link | "no subscriptions"}.
>>
+ //TODO These can be managed with #{app:app_anchor("io.picolabs.plan.relate")}.</p>
<<
<p>
It has #{child_count} child pico#{
  repo_pico => <<: "#{repo_name}"
<a href="#{meta:host}/sky/event/#{meta:eci}/none/ruleset/child_pico_not_needed?eci=#{child_eci}" onclick="return confirm('This cannot be undone, and source code may be lost if you proceed.')">del</a>.
>> | (one_child => "" | "s.")
}
</p>
>>
      + (repo_pico => <<<p>
You have a child pico which hosts apps from a repository that it maintains.
</p>
>> | "")
      + <<<h2>Technical</h2>
<button disabled title="not yet implemented">export</button>
>>
,_headers)
    }
    by = function(key){
      function(a,b){a{key}.encode() cmp b{key}.encode()}
    }
    channels = function(_headers){
      cs = wrangler:channels()
        .filter(function(c){c{"familyChannelPicoID"}.isnull()})
      one_channel = function(c){
        <<<tr>
<td><a href="channel.html?eci=#{c{"id"}}"><code>#{c{"id"}}</code></a></td>
<td>#{c{"tags"}.join(", ")}</td>
</tr>
>>
      }
      app:html_page("Your channels","",
      <<<h1>Your channels</h1>
<table>
<tr>
<td>ECI</td>
<td>tags</td>
</tr>
#{cs.sort(by("id")).map(one_channel).join("")}</table>
>>
,_headers)
    }
    channel = function(eci,_headers){
      this_c = wrangler:channels()
        .filter(function(c){c{"id"}==eci})
        .head()
      app:html_page(eci,"",
      <<<h1>Your <code>#{eci}</code> channel</h1>
<table>
<tr>
<td>ECI</td>
<td><code>#{this_c{"id"}}</code></td>
</tr>
<td>tags</td>
<td>#{this_c{"tags"}.join(", ")}</td>
</tr>
<tr>
<td>raw</td>
<td>#{this_c.encode()}</td>
</tr>
</table>
>>
,_headers)
    }
    participant_name = function(eci){
      thisPico = ctx:channels.any(function(c){c{"id"}==eci})
      thisPico => "yourself" | ctx:query(eci,"byu.hr.core","displayName")
    }
    subs_tags = function(s){
      wrangler:channels()
        .filter(function(c){c{"id"}==s{"Rx"}})
        .head()
        {"tags"}.join(", ")
    }
    subscriptions = function(_headers){
      ss = subs:established()
        .filter(function(s){s{"Tx_role"}!="participant list"})
      one_subs = function(s){
        <<<tr>
<td><a href="subscription.html?Id=#{s{"Id"}}"><code>#{s{"Id"}}</code></a></td>
<td>#{s{"Rx_role"}}</td>
<td>#{s{"Tx_role"}}</td>
<td>#{s{"Tx"}.participant_name()}</td>
<td>#{subs_tags(s)}</td>
</tr>
>>
      }
      app:html_page("Your subscriptions","",
      <<<h1>Your subscriptions</h1>
<table>
<tr>
<td>Id</td>
<td>your role</td>
<td>their role</td>
<td>with</td>
<td>channel tags</td>
</tr>
#{ss.sort(by("Id")).map(one_subs).join("")}</table>
>>
,_headers)
    }
    subscription = function(_headers,Id){
      this_s = subs:established("Id",Id).head()
      Rx = this_s{"Rx"}
      app:html_page(Id,"",
      <<<h1>Your <code>#{Id}</code> subscription</h1>
<table>
<tr>
<td>Id</td>
<td><code>#{this_s{"Id"}}</code></td>
</tr>
<tr>
<td>your channel</td>
<td><a href="channel.html?eci=#{Rx}"><code>#{Rx}</code></a></td>
</tr>
<tr>
<td>their channel</td>
<td><code>#{this_s{"Tx"}}</code></td>
</tr>
<tr>
<td>your role</td>
<td>#{this_s{"Rx_role"}}</td>
</tr>
<tr>
<td>their role</td>
<td>#{this_s{"Tx_role"}}</td>
</tr>
</tr>
<td>with</td>
<td>#{this_s{"Tx"}.participant_name()}</td>
</tr>
<tr>
<td>channel tags</td>
<td>#{subs_tags(this_s)}</td>
</tr>
</table>
>>
,_headers)
    }
    tags = ["app","introspections"] // to over-ride apps channel
  }
  rule initialize {
    select when io_picolabs_plan_introspect factory_reset
    pre {
      has_ruleset_ruleset = wrangler:installedRIDs() >< rsRID
      evd_for_rid = function(rid){
        rid.replace(re#[.-]#g,"_")
      }
    }
    every {
      wrangler:createChannel(
        tags,
        {"allow":[{"domain":evd_for_rid(meta:rid),"name":"*"},
                  {"domain":evd_for_rid(rsRID),"name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"},
                  {"rid":rsRID,"name":"*"}],"deny":[]}
      )
    }
    fired {
      raise io_picolabs_plan_introspect event "channel_created"
      raise wrangler event "install_ruleset_request" attributes {
        "absoluteURL":meta:rulesetURI,"rid":rsRID,
      } if not has_ruleset_ruleset
    }
  }
  rule keepChannelsClean {
    select when io_picolabs_plan_introspect channel_created
    foreach wrangler:channels(tags).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
}
