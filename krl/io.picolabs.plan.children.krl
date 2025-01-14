ruleset io.picolabs.plan.children {
  meta {
    name "Direct Children"
    use module io.picolabs.plan.apps alias app
    use module io.picolabs.wrangler alias wrangler
    shares children
  }
  global {
    children = function(_headers){
      app:html_page("manage Direct Children", "",
<<
<h1>Manage Direct Children</h1>
<h2>Technical</h2>
<pre>#{wrangler:children().encode()}</pre>
>>, _headers)
    }
  }
}
