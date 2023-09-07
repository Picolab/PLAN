ruleset io.picolabs.plan.connect {
  meta {
    name "DIDComm v2 connections"
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.plan.relate alias rel
    use module io.picolabs.plan.apps alias app
    use module io.picolabs.did-o alias dcv2
    use module oob
    shares connect, external, invitation, diddoc
  }
  global {
    invitation = function(label){
      oob:generate_invitation(label)
    }
    connect = function(_headers){
      did_docs = dcv2:didDocs()
      did_map = dcv2:didMap()
      app:html_page("manage DIDComm v2 connections", "",
<<
<h1>Manage DIDComm v2 connections</h1>
<h2><img src="https://manifold.picolabs.io/static/media/Aries.ffeeb7fd.png" alt="Aries logo" style="height:30px"> This is your Aries agent and cloud wallet</h2>
<h2>Connections based on  your established relationships:</h2>
<ul>
#{rel:relEstablished().map(function(r){
<<<li>You as <em>#{r.get("Rx_role")}</em> with #{r.get("Tx_name")} as <em>#{r.get("Tx_role")}</em>
</li>
>>
}).join("")}</ul>
<h2>External connections</h2>
<form action="#{meta:host}/c/#{meta:eci}/query/#{meta:rid}/external.html">
<button type="submit">make new external connection</button>
</form>
<ul>
#{did_map.keys().map(function(k){
<<<li>#{k.elide()} : #{did_map.get(k).elide()}</li>
>>}).join("")}</ul>
<h2>Technical</h2>
<h3>DIDDocs</h3>
<p>For this pico, there may be DIDDocs for used (or unused) invitations.</p>
<ul>
#{did_docs.keys().map(function(k){
<<<li title="#{k}"><a href="diddoc.html?did=#{k}">#{k.elide()}</a> #{extract_eci(did_docs.get(k))}</li>
>>}).join("")}</ul>
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
      eci = ecis.head()
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
}
