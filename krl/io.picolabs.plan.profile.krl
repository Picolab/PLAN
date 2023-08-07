ruleset io.picolabs.plan.profile {
  meta {
    name "Contact Information"
    use module io.picolabs.plan.apps alias app
    use module io.picolabs.pds alias pds
    use module io.picolabs.wrangler alias wrangler
    shares profile
  }
  global {
    cell_attrs = function(prompt){
      bits = [
        "","contenteditable",
        <<onfocus="cache_it(event)">>,
        <<onkeydown="munge(event)">>,
        <<onblur="save_it(event)">>,
      ]
      prompt == element_names.head() => "" | bits.join(" ")
    }
    on_click = function(prompt){
      prompt == element_names.head()
        => ""
         | << onclick="this.nextElementSibling.focus()">>
    }                         
    profile = function(_headers){
      app:html_page("manage Contact Information", scripts(),
<<
<h1>Manage Contact Information</h1>
<table>
#{[element_names,element_descriptions].pairwise(function(prompt,title){
<<<tr title="#{title}">
<td#{on_click(prompt)}>#{prompt}</td>
<td#{cell_attrs(prompt)}>#{pds:getData("profile",prompt)}</td>
</tr>
>>}).values().join("")}
</table>
<p>
You may edit your information: click, change, and press Enter key (or Esc to undo a change).
</p>
>>, _headers)
    }
    element_names = [
      "Agent name",
      "Your name",
      "Your phone number",
      "Your email address",
    ]
    element_descriptions = [
      "The name of your personal agent.",
      "A name you might want to appear in a roster of affiliates.",
      "A phone number you might want to appear in a roster of affiliates.",
      "An email address you might want to appear in a roster of affiliates.",
    ]
    scripts = function(){
      update_url = app:event_url(meta:rid,"new_field_value")
<<
    <script type="text/javascript">
      var updURL = "#{update_url}?";
      function cache_it(ev){
        var e = ev || window.event;
        var thespan = e.target.textContent;
        var thename = e.target.previousElementSibling.textContent;
        sessionStorage.setItem(thename,thespan);
        window.getSelection().selectAllChildren(e.target);
      }
      function munge(ev) {
        var e = ev || window.event;
        var keyCode = e.code || e.keyCode;
        if(keyCode==27 || keyCode==="Escape"){
          var thename = e.target.previousElementSibling.textContent;
          e.target.textContent = sessionStorage.getItem(thename);
          window.getSelection().removeAllRanges()
          e.target.blur();
        }else if(keyCode==13 || keyCode==="Enter"
            || keyCode==9 || keyCode==="Tab"){
          e.preventDefault();
          e.target.blur();
          return false;
        }
      }
      function save_it(ev){
        var e = ev || window.event;
        var thespan = encodeURIComponent(e.target.textContent);
        var thename = e.target.previousElementSibling.textContent;
        var oldspan = sessionStorage.getItem(thename);
        if(oldspan && oldspan !== thespan){
          var httpReq = new XMLHttpRequest();
          httpReq.open("GET",updURL+"name="+thename+"&value="+thespan);
          httpReq.send();
        }
      }
    </script>
>>
    }
  }
  rule initializeProfile {
    select when io_picolabs_plan_profile factory_reset
    fired {
      raise pds event "new_data_available" attributes {
        "domain": "profile",
        "key": element_names.head(),
        "value": wrangler:name()
      }
    }
  }
  rule updateField {
    select when io_picolabs_plan_profile new_field_value
      where element_names >< event:attr("name")
    pre {
      name = event:attr("name")
      valueString = event:attr("value") // XSS: .html:defendHTML()
      value = valueString == "null" => null | valueString
    }
    fired {
      raise pds event "new_data_available" attributes {
        "domain":"profile",
        "key":name,
        "value":value
      }
    }
  }
}
