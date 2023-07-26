ruleset io.picolabs.plan.about {
  meta {
    name "this agent"
    use module io.picolabs.plan.apps alias app
    use module io.picolabs.wrangler alias wrangler
    shares agent
  }
  global {
    agent = function(_headers){
      app:html_page("manage this agent", "",
<<
<h1>Manage this agent</h1>
<p>
This agent belongs to you.
You control it because you control your email address
<code>#{wrangler:name()}</code>.
</p>
<p>
This web page is part of your view of this agent.
Its location (<code>#{app:query_url(meta:rid,"agent.html")}</code>)
contains an event channel identifier (ECI)
(<code>#{meta:eci}</code>) which is
unique to you, this agent application, and this browser.
This identifier allows you to control
this agent in this browser.
No one else will be able to use it to control this agent.
</p>
<p>
You can use the page for as long as you wish.
When you want a new and different ECI for this agent,
simply return to the PLAN <a href="https://PLAN.picolabs.io/">main page</a>
and submit your email address again.
The new link in the email message you will receive will return
you here with a new ECI.
</p>
>>, _headers)
    }
  }
}
