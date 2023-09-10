ruleset io.picolabs.plan.message {
  meta {
    name "BasicMessages"
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.plan.apps alias app
    use module io.picolabs.did-o alias dcv2
    use module didcomm-v2.basicmessage alias basicmessage
    shares message
  }
  global {
    message = function(did,_headers){
      did => messages(did,_headers) | dids(_headers)
    }
    messages = function(did,_headers){
      bmTags = ["didcomm-v2","basicmessage"]
      bmECI = wrangler:channels(bmTags).head().get("id")
      name = wrangler:picoQuery(did,"io.picolabs.plan.profile","name",{})
      label = name => << a connection you have with #{name}>> | ""
      action_link = <<#{meta:host}/sky/event/#{bmECI}/none/didcomm_v2_basicmessage/message_to_send>>
      app:html_page("BasicMessages", "",
<<
<h1>BasicMessages</h1>
<h2>For DID #{did.elide() + label}</h2>
<div id="messaging">
<div id="messages">
</div>
<div id="send_message">
<form action="#{action_link}">
<input type="hidden" name="their_did" value="#{did}">
<input id="message_composition" name="message_text">
<button type="submit">Send ▷</button>
</form>
</div>
</div>
>>, _headers)
    }
    dids = function(_headers){
      connect_link = app:query_url("io.picolabs.plan.connect","connect.html")
      app:html_page("BasicMessages", "",
<<
<h1>BasicMessages</h1>
<p>
Please select a DID for one of your
<a href="#{connect_link}">connections</a>.
</p>
>>, _headers)
    }
    elide = function(did){
      did.length() < 30 => did
                         | did.substr(0,25) + "…"
    }
  }
}
