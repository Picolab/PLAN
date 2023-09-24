ruleset io.picolabs.plan.connect {
  meta {
    name "DIDComm v2 connections"
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.plan.relate alias rel
    use module io.picolabs.plan.apps alias app
    use module io.picolabs.plan.profile alias profile
    use module io.picolabs.did-o alias dcv2
    use module didcomm-v2.out-of-band alias oob
    shares connect, external, invitation, diddoc
  }
  global {
    invitation = function(label){
      oob:generate_invitation(label)
    }
    connect = function(_headers){
      did_docs = dcv2:didDocs()
      did_map = dcv2:didMap()
      inv_eci = wrangler:channels(["oob","ui"]).head().get("id")
      inv_url = <<#{meta:host}/sky/event/#{inv_eci}/none/didcomm_v2_out_of_band/invitation_needed>>
      app:html_page("manage DIDComm v2 connections", "",
<<
<h1>Manage DIDComm v2 connections</h1>
<h2><img src="https://manifold.picolabs.io/static/media/Aries.ffeeb7fd.png" alt="Aries logo" style="height:30px"> This is your Aries agent and cloud wallet</h2>
<h2>Connections based on  your established relationships:</h2>
<ul>
#{rel:relEstablished().map(function(r){
<<<li>You as <em>#{r.get("Rx_role")}</em> with #{r.get("Tx_name")} as <em>#{r.get("Tx_role")}</em>
<a href="#{inv_url}?label=#{r.get("Id")}">make connection</a>
</li>
>>
}).join("")}</ul>
<h2>External connections</h2>
<form action="#{meta:host}/c/#{meta:eci}/query/#{meta:rid}/external.html">
<button type="submit">make new external connection</button>
</form>
<ul>
#{did_map.keys().map(function(k){
  name = wrangler:picoQuery(k,"io.picolabs.plan.profile","name",{})
  title = name => << title="#{name}">> | ""
  message_link = app:query_url("io.picolabs.plan.message","message.html")
  <<<li>
<span#{title}>#{k.elide()}</span> : #{did_map.get(k).elide()}
<a href="#{message_link}?did=#{k}">messaging</a>
</li>
>>}).join("")}</ul>
<h3>Technical</h3>
<ul>
#{
  oob:connections()
    .map(function(c,k){
        <<<li>#{k} <pre>c.encode()</pre></li>
>>
      })
    .values()
    .join("")
}</ul>
<h2>Technical</h2>
<h3>DIDDocs</h3>
<p>For this pico, there may be extra DIDDocs for unused invitations.</p>
<ul>
#{
  did_docs.keys()
    .map(function(k){
        used = did_map.keys() >< k || did_map.values() >< k
        <<<li title="#{k}"><a href="diddoc.html?did=#{k}">#{k.elide()}</a> #{which_pico(did_docs.get(k))}
#{used => "" | <<<a href="#del">del<a\>>>}
</li>
>>
      }
    )
    .join("")
}</ul>
>>, _headers)
    }
    external = function(_headers){
      inv_link = app:query_url(meta:rid,"invitation")
      accept_link = app:event_url(meta:rid,"invitation_to_accept")
      acceptECI = wrangler:channels("aries,agent").head().get("id")
      app:html_page("manage DIDComm v2 connections", "",
<<
<h1>Make new external connection</h1>
<h2><img src="https://manifold.picolabs.io/static/media/Aries.ffeeb7fd.png" alt="Aries logo" style="height:30px"> This is your Aries agent and cloud wallet</h2>
<h2>Generate invitation:</h2>
<form method="GET" action="#{inv_link}.txt" target="_blank">
Label for invitation:
<input name="label" value="#{ent:agentLabel || wrangler:name()}">
<button type="submit">Invitation to copy</button> (opens in new tab)
</form>
<h2>Accept invitation:</h2>
<form method="POST" action="#{accept_link}">
Invitation you received:
<input name="uri">
<button type="submit">Accept invitation</button>
</form>
>>, _headers)
    }
    elide = function(did){
      did.length() < 30 => did
                         | did.substr(0,25) + "…"
    }
    diddoc = function(did,_headers){
      dd = dcv2:didDocs().get(did).encode()
      short_did = did.elide()
      css = <<<style>textarea{height:30em;width:60%;}</style>
>>
      app:html_page("DIDDoc for "+short_did,css,
<<<h1>DIDDoc for #{short_did}</h1>
<textarea id="diddoc" wrap="off" readonly></textarea>
<script type="text/javascript">
document.getElementById("diddoc").value
= JSON.stringify(JSON.parse('#{dd}'),null,2);
</script>
>>, _headers)
    }
    extract_eci = function(did_doc){
      urls = did_doc.get("service").map(function(sm){sm.get(["serviceEndpoint","uri"])})
      ecis = urls.map(function(u){u.extract(re#/event/([^/]*)/none/#).head()})
      ecis.head()
    }
    which_pico = function(did_doc){
      eci = extract_eci(did_doc)
      ctx:channels.any(function(c){c{"id"}==eci}) => "this pico" | "another pico"
    }
  }
  rule acceptInvitation {
    select when io_picolabs_plan_connect invitation_to_accept
      uri re#(.+)# setting(uri)
    fired {
      raise dido event "receive_invite" attributes {
        "invite": uri
      }
    }
  }
  rule redirectBack {
    select when io_picolabs_plan_connect invitation_to_accept
    pre {
      connect_link = app:query_url(meta:rid,"connect.html")
    }
    send_directive("_redirect",{"url":connect_link})
  }
  rule initializeAgentLabel {
    select when io_picolabs_plan_connect factory_reset
    pre {
      name = profile:name()
    }
    fired {
      ent:agentLabel := name
    }
  }
}
