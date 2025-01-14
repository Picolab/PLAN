ruleset io.picolabs.plan.children {
  meta {
    name "Direct Children"
    use module io.picolabs.plan.apps alias app
    shares children
  }
  global {
    children = function(_headers){
      app:html_page("manage Direct Children", "",
<<
<h1>Manage Direct Children</h1>
>>, _headers)
    }
  }
}
