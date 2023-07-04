ruleset hello-world {
  meta {
    name "greetings"
    use module io.picolabs.plan.apps alias app
    shares hello
  }
  global {
    hello = function(_headers){
      app:html_page("manage greetings", "",
<<
<h1>Manage greetings</h1>
<p>
Hello, #{ent:name || "World"}!
</p>

<h2>Change the name</h2>
<form action="#{app:event_url(meta:rid,"new_name_submission")}">
<input name="new_name" value="#{ent:name || "World"}"/>
<button type="submit">Submit</button>
</form>
>>, _headers)
    }
  }
  rule changeName {
    select when hello_world new_name_submission
    fired {
      ent:name := event:attrs{"new_name"}
    }
  }
  rule redirectToHomePage {
    select when hello_world new_name_submission
    send_directive("_redirect",{"url":app:query_url(meta:rid,"hello.html")})
  }
}
