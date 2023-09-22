ruleset io.picolabs.plan.M-journal {
  meta {
    name "Journal"
    use module io.picolabs.plan.apps alias app
    use module io.picolabs.plan.Manifold alias Mfd
    shares journal
  }
  global {
    journal = function(eci,_headers){
      journal_query = function(name){
        Mfd:Mq()+eci+"/io.picolabs.journal/"+name
      }
      journal_entries = http:get(journal_query("getEntry"))
        .get("content").decode()
      app:html_page("Journal", "",
<<
<h1>Journal</h1>
#{journal_entries.reverse().map(
  function(e){
    tMDT = time:add(e.get("timestamp"),{"hours": -6})
      .replace(re#.\d\d\dZ#," MDT").replace("T"," ")
    <<<h2 style="margin-bottom:0px">#{e.get("title")}</h2>
<span style="font-size:12px;color:grey">#{tMDT}</span>
<p>#{e.get("content")}</p>
>>
  }
).join("")}
>>, _headers)
    }
  }
}
