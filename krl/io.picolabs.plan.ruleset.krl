ruleset io.picolabs.plan.ruleset {
  meta {
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.plan.introspect alias intro
    use module io.picolabs.plan.apps alias app
    shares rulesets, ruleset, repo_krl, repo_uiECI, krl, codeEditor
  }
  global {
    pf = re#^file:///.*/lib/node_modules/#
    pu = "https://raw.githubusercontent.com/Picolab/pico-engine/master/packages/"
    by = function(key){
      function(a,b){a{key}.encode() cmp b{key}.encode()}
    }
    rulesets = function(_headers){
      xref = module_usage()
      deet = <<#{meta:host}/c/#{meta:eci}/query/#{meta:rid}/ruleset.html?rid=>>
      apps = app:app_list()
      sort_key = ["meta","flushed"]
      one_ruleset = function(rs){
        rid = rs{"rid"}
        module_xref = xref{rid}
        module_title = module_xref.length()==0 => ""
          | << title="used as module by #{module_xref.join(", ")}">>
        flushed_time = rs{sort_key}
          .encode().decode() // work around issue #602
        url = rs{"url"}.replace(pf,pu)
        meta_hash = rs{["meta","hash"]}
        <<<tr>
<td#{module_title}><a href="#{deet+rid}">#{rid}</a></td>
<td>#{apps >< rid => app:app_anchor(rid) | ""}</td>
<td title="#{flushed_time}">#{flushed_time.makeMT().ts_format()}</td>
<td><a href="#{url}" target="_blank">#{url}</a></td>
<td title="#{meta_hash}">#{meta_hash.substr(0,7)}</td>
</tr>
>>
      }
      app:html_page("Your rulesets","",
      <<<h1>Your rulesets</h1>
<table>
<tr>
<td>Ruleset ID</td>
<td>App</td>
<td>Last flushed</td>
<td>Source code</td>
<td>Hash</td>
</tr>
#{ctx:rulesets.sort(by(sort_key)).map(one_ruleset).join("")}</table>
>>
,_headers)
    }
    makeMT = function(ts){
      MST = time:add(ts,{"hours": -7});
      MDT = time:add(ts,{"hours": -6});
      MDT > "2025-11-02T02" => MST |
      MST > "2025-03-09T02" => MDT |
      MDT > "2024-11-03T02" => MST |
      MST > "2024-03-10T02" => MDT |
                               MST
    }
    ts_format = function(ts){
      parts = ts.split(re#[T.]#)
      parts.filter(function(v,i){i<2}).join(" ")
    }
    r_use_m_relation = function(){ // a set (an Array) of ordered pairs
      add_relations = function(set,rs){
        rid = rs{"rid"}
        ops = rs{["meta","krlMeta","use"]}
          .defaultsTo([])
          .filter(function(v){v{"kind"}=="module"})
          .map(function(u){[rid,u{"rid"}]})
        set.append(ops)
      }
      ctx:rulesets
        .reduce(add_relations,[])
    }
    module_usage = function(){
      xref = function(amap,op){
        r = op.head()
        m = op[1]
        amap.put(m,amap.get(m).defaultsTo([]).append(r))
      }
      r_use_m_relation() // set of (rid,module) ordered pairs
        .reduce(xref,{})
    }
    ruleset = function(rid,_headers){
      apps = app:app_list()
      rs = ctx:rulesets.filter(function(r){r{"rid"}==rid}).head()
      xref = module_usage()
      module_xref = xref{rid}
      exclude = function(x){function(v){v != x}}
      flushed_time = rs{["meta","flushed"]}
        .encode().decode() // work around issue #602
      url = rs{"url"}.replace(pf,pu)
      meta_hash = rs{["meta","hash"]}
      source_krl = http:get(url){"content"}
      source_hash = math:hash("sha256",source_krl)
      redden = source_hash == meta_hash => ""
                                         | << style="color:red">>
      editURL = <<#{meta:host}/sky/event/#{meta:eci}/none/io_picolabs_plan_ruleset/app_needs_edit>>
      editable_app = rid != "byu.hr.record" && rid != "io.picolabs.plan.apps"
      app:html_page(rid,"",
      <<<h1>Your ruleset <code>#{rid}</code></h1>
<table>
<tr>
<td>RID</td>
<td>#{rid}</td>
</tr>
<tr>
<td>Provides</td>
<td>#{rs{["meta","krlMeta","provides"]}
       .defaultsTo(["nothing"])
       .join(", ")
     }</td>
</tr>
<tr>
<td>Used as module</td>
<td>#{module_xref.length()==0 => "No" | module_xref.join(", ")}</td>
</tr>
<tr>
<td>Shares</td>
<td>#{rs{["meta","krlMeta","shares"]}
        .defaultsTo([])
        .filter(exclude("__testing"))
        .join(", ")
     }</td>
</tr>
<tr>
<td>App</td>
<td>#{apps >< rid => app:app_anchor(rid) | "No"}</td>
</tr>
<tr>
<td>Last flushed</td>
<td title="#{flushed_time}">#{flushed_time.makeMT().ts_format()}</td>
</tr>
<tr>
<td>Config</td>
<td>#{rs{"config"}.encode()}</td>
</tr>
<tr>
<td>Source code</td>
<td><a href="#{url}" target="_blank">#{url}</a></td>
</tr>
<tr>
<td>Source code hash</td>
<td title="#{source_hash}">#{source_hash.substr(0,7)}</td>
</tr>
<tr>
<td>Internal hash</td>
<td title="#{meta_hash}"#{redden}>#{meta_hash.substr(0,7)}</td>
</tr>#{
source_hash == meta_hash => <<
>> |
<<
<tr>
<td>Internal</td>
<td><a href="#{meta:host}/c/#{meta:eci}/query/#{meta:rid}/krl.txt?rid=#{rid}">source</a></td>
</tr>
>>
}</table>
>>
      + (apps >< rid => <<
<br>
<form action="#{editURL}">
<input type="hidden" name="rid" value="#{rid}">
<button type="submit"#{editable_app => "" | << disabled title="not editable">>}>Edit app KRL</button>
</form>
>> | "")
,_headers)
    }
    repo_rid = "com.vcpnews.repo"
    repo_name = function(){
      netid = wrangler:name()
      netid+"/bazaar"
    }
    repo_pico = function(){
      the_name = repo_name()
      wrangler:children()
        .filter(function(c){
          c{"name"} == the_name
        })
        .head()
    }
    repo_eci = function(){
      repo = repo_pico()
      wrangler:picoQuery(repo{"eci"},repo_rid,"pico_eci")
    }
    repo_krl = function(rid){
      repo = repo_pico()
      repo.isnull() => "no repo" |
      wrangler:picoQuery(
        repo{"eci"},
        repo_rid,
        "krl",
        {"rid":rid}
      )
    }
    repo_uiECI = function(){
      repo = repo_pico()
      repo.isnull() => "no repo" |
      wrangler:picoQuery(repo{"eci"},"io.picolabs.pico-engine-ui","uiECI")
    }
    krl = function(rid){
      rs = ctx:rulesets.filter(function(r){r{"rid"}==rid}).head()
      rs{["meta","krl"]}
    }
    codeEditor_css = <<<style type="text/css">
  #codeEditor, #lineCounter {
    font-family: lucida console, courier new, courier, monospace;
    margin: 0;
    padding: 10px 0;
    height: 75vh;
    border-radius: 0;
    resize: none;
    font-size: 16px;
    line-height: 1.2;
    outline: none;
    -moz-box-sizing: border-box;
    -webkit-box-sizing: border-box;
    box-sizing: border-box;
  }
  #codeEditor {
    padding-left: calc(3.5rem + 5px);
    width:100%;
    /* Determine appearance of code editor */
    background-color:#272822;
    border-color:#272822;
    color:#ffffff;
  }
  #codeEditor.light {
    background-color:white;
    border-color:white;
    color:#272822;
  }
  #lineCounter {
    display: flex;
    border-color: transparent;
    overflow-y: hidden;
    text-align: right;
    box-shadow: none;
    color: #707070;
    background-color: #d8d8d8;
    position: absolute;
    width: 3.5rem;
    /* Determine appearance of line counter */
    background-color:#3E3D32;
    border-color:#3E3D32;
    color:#928869;
  }
  #lineCounter:focus-visible,
  #codeEditor:focus-visible {
    outline:none;
  }
</style>
>>
    codeEditor = function(rid,_headers){
      the_repo_eci = repo_eci()
      rawURL = <<#{meta:host}/c/#{the_repo_eci}/query/#{repo_rid}/krl.txt?rid=#{rid}>>
      app:html_page(rid,codeEditor_css,
      <<<div style="float:right">
<fieldset>
<legend>Theme</legend>
<input type="radio" id="dark" name="theme" checked onclick="document.getElementById('codeEditor').classList.remove('light')">
<label for="dark">Dark</label>
<input type="radio" id="light" name="theme" onclick="document.getElementById('codeEditor').classList.add('light')">
<label for="light">Light</label>
</fieldset>
</div>
<h2>📝 Code Editor</h2>
<p><textarea id="lineCounter" wrap="off" readonly>1.</textarea><textarea id="codeEditor" wrap="off" spellcheck="false"></textarea></p>
<script type="text/javascript">
  var codeEditor = document.getElementById('codeEditor');
  var lineCounter = document.getElementById('lineCounter');
  
  var lineCountCache = 0;
  function line_counter() {
    var lineCount = codeEditor.value.split('\n').length;
    var outarr = new Array();
    if (lineCountCache != lineCount) {
      for (var x = 0; x < lineCount; x++) {
          outarr[x] = (x + 1) + '.';
      }
      lineCounter.value = outarr.join('\n');
    }
    lineCountCache = lineCount;
  }

  codeEditor.addEventListener('scroll', () => {
    lineCounter.scrollTop = codeEditor.scrollTop;
    lineCounter.scrollLeft = codeEditor.scrollLeft;
  });

  codeEditor.addEventListener('input', () => {
    line_counter();
  });

  codeEditor.addEventListener('keydown', (e) => {
    let { keyCode } = e;
    let { value, selectionStart, selectionEnd } = codeEditor;

    if (keyCode === 9) {  // TAB = 9
      e.preventDefault();
      codeEditor.value = value.slice(0, selectionStart) + '\t' + value.slice(selectionEnd);
      codeEditor.setSelectionRange(selectionStart+2, selectionStart+1)
    }
  });

  codeEditor.value = '';
  line_counter();
</script>
<script>
  var xhr = new XMLHttpRequest;
  xhr.onload = function(){
    var data = xhr.response;
    if(data && data.length){
      codeEditor.value = data;
      line_counter();
    }
  }
  xhr.onerror = function(){alert(xhr.responseText);}
  xhr.open("GET","#{rawURL}",true);
  xhr.send();
</script>
<form action="#{meta:host}/sky/event/#{the_repo_eci}/save/introspect_repo/source_changed" method="POST">
<input name="rid" value="#{rid}">
<input name="src" type="hidden">
<button type="submit" onclick="form.src.value=codeEditor.value">Save</button>
</form>
<p>Raw URL: <a href="#{rawURL}" target="_blank">#{rawURL}</a></p>
>>
,_headers)
    }
  }
  rule createRepoChildIfNeeded {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    pre {
      repo = repo_pico()
    }
    if repo then noop()
    fired {
      // repo pico already exists
    }
    else {
      raise wrangler event "new_child_request" attributes
        event:attrs.put("name",repo_name())
    }
  }
  rule reactToChildCreation {
    select when wrangler:new_child_created
    pre {
      child_eci = event:attr("eci")
    }
    if child_eci then
      event:send({"eci":child_eci,
        "domain":"wrangler","type":"install_ruleset_request",
        "attrs":{"absoluteURL": meta:rulesetURI,"rid":repo_rid}
      })
    fired {
      raise ruleset event "repo_installed" // terminal event
    }
  }
  rule deleteChildPico {
    select when io_picolabs_plan_ruleset child_pico_not_needed
      eci re#(.+)# setting(eci)
    pre {
      referrer = event:attr("_headers").get("referer") // [sic]
    }
    send_directive("_redirect",{"url":referrer})
    fired {
      raise wrangler event "child_deletion_request" attributes {"eci":eci}
    }
  }
  rule deleteThisRuleset {
    select when io_picolabs_plan_apps app_unwanted
      rid re#^io.picolabs.plan.introspect$#
    fired {
      raise wrangler event "uninstall_ruleset_request"
        attributes event:attrs.put("rid",meta:rid)
    }
  }
  rule sendSourceCode {
    select when io_picolabs_plan_ruleset app_needs_edit
      rid re#(.+)#
      setting(rid)
    pre {
      has = repo_krl() >< rid
      repo = repo_pico()
    }
    if not has then
      event:send({
        "eci": repo{"eci"},
        "domain": "introspect_repo", "type": "new_source",
        "attrs": {"rid": rid, "src": krl(rid)}
      })
  }
  rule openNewEditor {
    select when io_picolabs_plan_ruleset app_needs_edit
      rid re#(.+)#
      setting(rid)
    pre {
      url = <<#{meta:host}/c/#{meta:eci}/query/#{meta:rid}/codeEditor.html?rid=#{rid}>>
    }
    send_directive("_redirect",{"url":url})
  }
}
