ruleset io.picolabs.plan.M-safeandmine {
  meta {
    name "Safe and Mine"
    use module io.picolabs.plan.apps alias app
    use module io.picolabs.plan.Manifold alias Mfd
    shares safeandmine
  }
  global {
    safeandmine = function(eci,_headers){
      safeandmine_query = function(name){
        Mfd:Mq()+eci+"/io.picolabs.safeandmine/"+name
      }
      info = http:get(safeandmine_query("getInformation"))
        .get("content")
        .decode()
      tags = http:get(safeandmine_query("getTags"))
        .get("content")
        .decode()
      app:html_page("Safe and Mine", "",
<<
<h1>Safe and Mine</h1>
<h2>Message</h2>
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
<h2>Tags</h2>
<dl>#{
  tags.map(function(v,k){
    <<<dt>#{k}</dt><dd>#{v.join(", ")}</dd>
>>
  }).values().join("")
}</dl>
>>, _headers)
    }
  }
}
