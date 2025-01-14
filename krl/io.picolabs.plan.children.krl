ruleset io.picolabs.plan.children {
  meta {
    name "Direct Children"
    use module io.picolabs.plan.apps alias app
    use module io.picolabs.wrangler alias wrangler
    shares children
  }
  global {
    uiRID = "io.picolabs.pico-engine-ui"
    children = function(_headers){
      direct_children = wrangler:children()
      app:html_page("manage Direct Children", "",
<<
<h1>Manage Direct Children</h1>
<h2>Technical</h2>
<dl>
#{direct_children.map(function(c){
  the_box = wrangler:picoQuery(c{"eci"},uiRID,"just_box")
  <<<dt>#{c{"name"}}</dt><dd><pre>#{the_box.encode()}</pre></dd>
>>
}).join("")}</dl>
>>, _headers)
    }
  }
}
