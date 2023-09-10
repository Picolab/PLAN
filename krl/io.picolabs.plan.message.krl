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
    message = function(did,_headers) {
      did => messages(did,_headers) | dids(_headers)
    }
    messages = function(did,_headers) {
      bmTags = ["didcomm-v2","basicmessage"]
      bmECI = wrangler:channels(bmTags).head().get("id")
      name = wrangler:picoQuery(did,"io.picolabs.plan.profile","name",{})
      label = name => << a connection you have with #{name}>> | ""
      action_link = <<#{meta:host}/sky/event/#{bmECI}/none/didcomm_v2_basicmessage/message_to_send>>
      app:html_page(
        "BasicMessages",
        <<<style type="text/css">
#messaging {
  max-height: 60vh;
  width: 30%;
  overflow: hidden;
  overflow-y: auto;
  background-color: white;
  padding: 10px;
}
#messaging p {
  margin: 2px 0;
  padding: 10px;
  border: 1px solid black;
  border-radius: 15px;
  max-width: 80%;
  clear: both;
  overflow-x: auto;
}
#messaging .incoming {
  float: left;
  border-bottom-left-radius: 0;
}
#messaging .outgoing {
  float: right;
  border-bottom-right-radius: 0;
}
#send_message {
  clear: both;
  float: right;
  margin: 5px 0 0 0;
}
</style>
>>,
        <<<h1>BasicMessages</h1>
<h2>For DID #{did.elide() + label}</h2>
<div id="messaging">
<div id="messages">
#{ent:messages{did}.defaultsTo([]).map(function(m){
  msg_time = time:add(m.get("created_time"),{"hours": -6})
    .replace(re#.000Z#," MDT").replace("T"," ")
  <<<p class="#{m.get("from")}" title="#{msg_time}">#{m.get("message_text")}</p>
>>}).join("")}
</div>
<div id="send_message">
<form action="#{action_link}">
<input type="hidden" name="their_did" value="#{did}">
<input id="message_composition" name="message_text" autofocus>
<button type="submit">Send ▷</button>
</form>
</div>
</div>
>>,
        _headers)
    }
    dids = function(_headers) {
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
  rule initializeOnInstallation {
    select when io_picolabs_plan_message factory_reset
      where ent:messages.isnull()
    fired {
      ent:messages := {}
    }
  }
  rule incomingMessge {
    select when didcomm_v2_basicmessage message_received
    pre {
      message = event:attrs{"message"}
      their_did = message{"from"}
      msg = {
        "their_did": their_did,
        "message_text": message{["body","content"]},
        "created_time": time:new(message{"created_time"}*1000),
        "from": "incoming",
      }
      old_messages = ent:messages{their_did}.defaultsTo([])
    }
    fired {
      ent:messages{their_did} := old_messages.append(msg)
    }
  }
  rule outgoingMessge {
    select when didcomm_v2_basicmessage message_sent
    pre {
      message = event:attrs{"message"}
      their_did = message{"to"}.head()
      msg = {
        "their_did": their_did,
        "message_text": message{["body","content"]},
        "created_time": time:new(message{"created_time"}*1000),
        "from": "outgoing",
      }
      old_messages = ent:messages{their_did}.defaultsTo([])
    }
    fired {
      ent:messages{their_did} := old_messages.append(msg)
    }
  }
}
