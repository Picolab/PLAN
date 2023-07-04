ruleset com.vcpnews.fav-color {
  meta {
    name "Favorite Color"
    use module io.picolabs.plan.apps alias app
    use module css3colors alias colors
    shares index
  }
  global {
    index = function(_headers){
      app:html_page("manage Favorite Color", "",
<<
<h1>Manage Favorite Color</h1>
#{ent:colorname => <<<p>Your favorite color:</p>
<table style="background-color:white">
  <thead>
    <tr>
      <th scope="col">Name</th>
      <th scope="col">RGB hex</th>
      <th scope="col">Swatch</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style="text-align:center"><code>#{ent:colorname}</code></td>
      <td><code>#{ent:colorcode}</code></td>
      <td style="background-color:#{ent:colorcode}"></td>
    </tr>
  </tbody>
</table>
>> | <<<p>You have not yet selected a favorite color.</p>
>>}<hr>
<form action="#{app:event_url(meta:rid,"fav_color_selected")}" method="POST">
Favorite color: <select name="fav_color">
#{colors:options("  ",ent:colorname)}</select>
<button type="submit">Select</button>
</form>
>>, _headers)
    }
  }
  rule recordFavColor {
    select when com_vcpnews_fav_color fav_color_selected
      fav_color re#^(\#[a-f0-9]{6})$# setting(fav_color)
    pre {
      colorname = colors:colormap.filter(function(v){v==fav_color}).keys().head()
        || "unknown"
    }
    fired {
      ent:colorname := colorname
      ent:colorcode := fav_color
      raise com_vcpnews_fav_color event "fav_color_recorded" attributes {
        "colorcode":fav_color,
        "colorname":colorname,
      }
    }
  }
  rule redirectBack {
    select when com_vcpnews_fav_color fav_color_selected
    pre {
      referrer = event:attr("_headers").get("referer") // sic
    }
    if referrer then send_directive("_redirect",{"url":referrer})
  }
}
