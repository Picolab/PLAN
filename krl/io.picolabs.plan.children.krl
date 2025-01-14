ruleset io.picolabs.plan.children {
  meta {
    name "Direct Children"
    use module io.picolabs.plan.apps alias app
    use module io.picolabs.wrangler alias wrangler
    shares children, tech
  }
  global {
    uiRID = "io.picolabs.pico-engine-ui"
    styles = <<<style>
.r { resize:both;overflow:auto; }
.b { border:1px solid black; }
a#tech { float:right; text-decoration:none; margin:0.5em; }
a#docs { float:right; text-decoration:none; margin:0.5em; }
</style>
>>
    one_pico = function(box){
      pico_style = [
        <<width:#{box{"width"}}px>>,
        <<height:#{box{"height"}}px>>,
        <<background-color:#{box{"backgroundColor"}}>>,
        "border-radius: .25rem"
      ].join(";")
      <<<table style="position:absolute;top:0px;left:0px">
  <tr>
    <td class="r" style="width:#{box{"x"}}px;height:#{box{"y"}}px"></td>
    <td></td>
  </tr>
  <tr title="#{box.encode().replace(re#"#g,"&quot;")}">
    <td></td>
    <td class="b r" style="#{pico_style}" contenteditable>#{box{"name"}}</td>
  </tr>
</table>
>>
    }
    children = function(_headers){
      direct_children = wrangler:children()
      tech_url = app:query_url(meta:rid,"tech")
      app:html_page("manage Direct Children", styles,
<<
<a id="tech" href="#{tech_url}" title="Technical Details">⚙️</a>
<a id="docs" href="#" title="How to move/resize">ℹ️</a>
<h1>Manage Direct Children</h1>
#{direct_children.map(function(c){
  the_box = wrangler:picoQuery(c{"eci"},uiRID,"just_box")
  one_pico(the_box)
}).join("")}
>>, _headers)
    }
    tech = function(_headers){
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
<!--
TODO add button to create an additional child pico
-->
>>, _headers)
    }
  }
}
