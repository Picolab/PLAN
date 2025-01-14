ruleset io.picolabs.plan.children {
  meta {
    name "Direct Children"
    use module io.picolabs.plan.apps alias app
    use module io.picolabs.wrangler alias wrangler
    shares children
  }
  global {
    uiRID = "io.picolabs.pico-engine-ui"
    styles = <<<style>
.r { resize:both;overflow:auto; }
.b { border:1px solid black; }
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
  <tr title="#{box.encode()}">
    <td></td>
    <td class="b r" style="#{pico_style}" contenteditable>#{box{"name"}}</td>
  </tr>
</table>
>>
    }
    children = function(_headers){
      direct_children = wrangler:children()
      app:html_page("manage Direct Children", styles,
<<
<h1>Manage Direct Children</h1>
#{direct_children.map(function(c){
  the_box = wrangler:picoQuery(c{"eci"},uiRID,"just_box")
  one_pico(the_box)
}).join("")}
<!--
<h2>Technical</h2>
<dl>
#{direct_children.map(function(c){
  the_box = wrangler:picoQuery(c{"eci"},uiRID,"just_box")
  <<<dt>#{c{"name"}}</dt><dd><pre>#{the_box.encode()}</pre></dd>
>>
}).join("")}</dl>
TODO add button to create an additional child pico
-->
>>, _headers)
    }
  }
}
