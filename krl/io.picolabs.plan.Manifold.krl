ruleset io.picolabs.plan.Manifold {
  meta {
    name "Manifold things"
    use module io.picolabs.plan.apps alias app
    shares things, thing, setup
  }
  global {
    things = function(_headers){
      ent:host && ent:key => things_list(_headers) | setup(_headers)
    }
    Mq = function(host,port){
      h = host || ent:host
      p = port || ent:port
      "https://" + h + (p => ":" + p | "") + "/sky/cloud/"
    }
    Me = function(eci,eid="none"){
      h = ent:host
      p = ent:port
      "https://" + h + (p => ":" + p | "") + "/sky/event/" + eci + "/" + eid + "/"
    }
    things_list = function(_headers){
      app:html_page("Manifold things", "",
<<
<h1
  style="float:right;cursor:pointer"
  title="Setup"
  onclick="location='setup.html'">⚙</h1>
<h1>Manifold things</h1>
<ul>
#{
  ent:things_list.values().map(function(v,i){
    base_url = app:query_url(meta:rid,"thing.html")
    <<<li><a href="#{base_url}?eci=#{v.get("Tx")}">#{v.get("name")}</a></li>
>>
  }).join("")
}</ul>
>>, _headers)
    }
    setup = function(_headers){
      h = ent:host => << value="#{ent:host}">> | ""
      p = ent:port => << value="#{ent:port}">> | ""
      app:html_page("Manifold setup", "",
<<
<h1>Manifold setup</h1>
<form action="#{app:event_url(meta:rid,"setup_provided")}">
<h2>Host and port</h2>
<input name="host" required#{h}>:<input name="port" type="number"#{p}>
<h2>Key</h2>
<input name="key" size="30" required>
<h2>Submit</h2>
<button type="submit">Submit</button>
</form>
>>, _headers)
    }
    thing = function(eci,_headers){
      apps = http:get(Me(eci)+"manifold/apps")
        .get("content")
        .decode()
        .get("directives")
        .filter(function(d){d{"name"}=="app discovered..."})
        .collect(function(a){a.get(["options","app","name"])})
        .map(function(o){o.head().get("options")})
      safeandmine_query = function(name){
        Mq()+eci+"/io.picolabs.safeandmine/"+name
      }
      info = http:get(safeandmine_query("getInformation"))
        .get("content")
        .decode()
      tags = http:get(safeandmine_query("getTags"))
        .get("content")
        .decode()
      the_thing = ent:things_list.values()
        .filter(function(v){v.get("Tx") == eci}).head()
      the_thing_name = the_thing.get("name")
      the_thing_picoId = the_thing.get("picoId")
      app_list = app:app_list()
      app:html_page(the_thing_name,"",
<<
<h1>#{the_thing_name}</h1>
<h2>Manifold apps</h2>
<ul style="list-style-type:none">
#{apps.map(
  function(v,k){
    deprecated = k.match(re# agent$#i)
    known = k.match(re#safeandmine|journal#)
    planRID = v.get("rid").replace("io.picolabs.","io.picolabs.plan.M-")
    have_app = app_list >< planRID
    plan_title = have_app => "" | << title="#{"need app " + planRID}">>
    plan_link = have_app => app:query_url(planRID,k+".html?eci="+eci) | "#"
    app_link = known && have_app => <<<a href="#{plan_link}">#{k}</a\>>> | k
    styles = [
      "width:25px",
      "border-radius:5px",
      "vertical-align:middle",
      "margin:5px 0",
    ]
    <<<li>
<img src="#{v.get("iconURL")}" alt="#{k} icon" style="#{styles.join(";")}">
<span#{plan_title}>#{app_link}#{deprecated => " (deprecated)" | ""}</span>
</li>
>>
  }
).values().join("")}</ul>
<h2>Safe and Mine</h2>
<h3>Message</h3>
<div style="border:1px solid silver;max-width:40vw;padding:0 10px">#{
  [["Owner","Phone","Email","Owner's Public Message"],
  [
    info.get("shareName") => info.get("name") | "",
    info.get("sharePhone") => info.get("phone") | "",
    info.get("shareEmail") => info.get("email") | "",
    info.get("message"),
  ]].pairwise(function(a,b){
      b => <<<p><strong>#{a}:</strong> #{b}</p>
>> | ""
    }).join("")
}</div>
<h3>Tags</h3>
<dl>#{
  tags.map(function(v,k){
    <<<dt>#{k}</dt><dd>#{v.join(", ")}</dd>
>>
  }).values().join("")
}</dl>
<h3>Manifold page</h3>
<p>Assuming you are logged in to Manifold.</p>
<pre>https://manifold.picolabs.io/#/mythings/#{the_thing_picoId}</pre>
<h2>Technical</h2>
<h3>Thing as known to Manifold</h3>
<pre><script type="text/javascript">
document.write(JSON.stringify(#{the_thing.encode()},null,2))
</script></pre>
>>, _headers)
    }
  }
  rule acceptSetup {
    select when io_picolabs_plan_Manifold setup_provided
      host re#(.+)#
      port re#(.*)#
      key re#(.+)#
      setting(host,port,key)
    pre {
      url = Mq(host,port) + key
          + "/io.picolabs.manifold_pico/getThings"
      the_list = http:get(url).get("content").decode()
    }
    fired {
      ent:host := host
      ent:port := port
      ent:key := key
      ent:things_list := the_list
    }
  }
  rule redirectBack {
    select when io_picolabs_plan_Manifold setup_provided
    pre {
      url = app:query_url(meta:rid,"things.html")
    }
    send_directive("_redirect",{"url":url})
  }
}
