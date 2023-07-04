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
Hello, World!
</p>
>>, _headers)
    }
  }
}
