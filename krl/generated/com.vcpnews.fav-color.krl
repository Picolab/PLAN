ruleset com.vcpnews.fav-color {
  meta {
    name "Favorite Color"
    use module io.picolabs.plan.apps alias app
    shares index
  }
  global {
    index = function(_headers){
      app:html_page("manage Favorite Color", "",
<<
<h1>Manage Favorite Color</h1>
>>, _headers)
    }
  }
}
