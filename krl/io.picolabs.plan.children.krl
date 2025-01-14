ruleset io.picolabs.plan.children {
  meta {
    name "Direct Children"
    use module io.picolabs.plan.apps alias app
    use module io.picolabs.wrangler alias wrangler
    shares children
  }
  global {
    uiRID = "io.picolabs.pico-engine-ui"
    get_box = function(eci){
      uiECI = wrangler:picoQuery(eci,uiRID,"uiECI")
      uiECI => wrangler:picoQuery(uiECI,uiRID,"box") | null
    }
    children = function(_headers){
      direct_children = wrangler:children()
      app:html_page("manage Direct Children", "",
<<
<h1>Manage Direct Children</h1>
<h2>Technical</h2>
<pre>#{direct_children.encode()}</pre>
<dl>
#{direct_children.map(function(c){
  <<<dt>${c{"name"}}</dt><dd><pre>get_box(c{"eci"}).encode()</pre></dd>
>>
})}</dl>
>>, _headers)
    }
  }
}
