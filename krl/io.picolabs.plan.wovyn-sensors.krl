ruleset io.picolabs.plan.wovyn-sensors {
  meta {
    name "Wovyn sensors"
    use module io.picolabs.plan.apps alias app
    use module io.picolabs.wrangler alias wrangler
    shares wovyn_sensor, history, settings,
      export_tsv, export_csv, export_raw
    provides daysInRecord, export_csv, summary
  }
  global {
    settings_link = function(){
      app:query_url(meta:rid,"settings.html")
    }
    settings = function(_headers){
      hb_link = app:event_url(meta:rid,"heartbeat","hb")
        .replace(meta:eci,ent:sensor_channel_id)
      del_link = app:event_url(meta:rid,"sensor_not_needed")
      add_link = app:event_url(meta:rid,"sensor_needed")
      app:html_page("Wovyn sensor settings","",
      <<
<h1>Wovyn sensor settings</h1>
<h2>Heartbeat input URL</h2>
<pre>#{hb_link}</pre>
<h2>Device mapping</h2>
<form method="POST" action="#{add_link}">
<table>
<tr>
<th>#</th>
<th style="text-align:left">Name</th>
<th style="text-align:left">Location</th>
<th>Remove</th>
</tr>
<tr>
<td></td>
<td><input name="name"></td>
<td><input name="location"</td>
<td><button type="submit">Insert</button></td>
</tr>
#{
  ent:mapping
    .keys()
    .map(
      function(k,i){
        v = ent:mapping{k}
        <<<tr>
<td>#{i+1}</td>
<td>#{k}</td>
<td>#{v}</td>
<td><a href="#{del_link}?name=#{k}">del</a></td>
</tr>
>>
      }
    )
    .values()
    .join("")
}</table>
</form>
>>, _headers)
    }
    daysInRecord = function(){ // finds all dates in the data
      earlyHour = function(v,i){ // sample one early hour in the day
        i%2==0
        &&
        v.encode().decode().match(re#T07#) // one a.m. MDT / midnight MST
      }
      flatten = function(a,v){a.append(v)}
      justDate = function(t){t.split("T").head()}
      asSet = function(a,t){a.union(t)}
      ent:record
        .values()
        .map(function(list){list.filter(earlyHour)})
        .reduce(flatten,[])
        .map(justDate)
        .reduce(asSet,[])
        .sort()
    }
    makeMT = function(ts){
      MST = time:add(ts,{"hours": -7});
      MDT = time:add(ts,{"hours": -6});
      MDT > "2024-11-03T02" => MST |
      MST > "2024-03-10T02" => MDT |
                               MST
    }
    ts_format = function(ts){
      parts = ts.split(re#[T.]#)
      parts.filter(function(v,i){i<2}).join(" ")
    }
    temps = function(a,tt,i){
      a+(i%2==0 => <<<tr>
<td title="#{tt}">#{tt.makeMT().ts_format()}</td>
>> | <<
<td>#{tt}°F</td>
</tr>
>>)
    }
    wovyn_sensor = function(_headers){
      one_sensor = function(k){
        v = ent:record.get(k)
        vlen = v.length()
        <<<h2 title="#{k}">#{ent:mapping{k}}</h2>
<table>
<tr>
<th>Timestamp</th>
<th>Temperature</th>
</tr>
#{v.slice(vlen-2,vlen-1).reduce(temps,"").join("")}
</table>
<a href="history.html?name=#{k}">history</a>
(#{vlen/2-1} more)
>>
      }
      gear_styles = [
        "float:right",
        "text-decoration:none",
        "margin:0.5em",
      ]
      app:html_page("Wovyn sensors","",
      <<
<a style="#{gear_styles.join(";")}" href="#{settings_link()}">⚙️</a>
<h1>Wovyn sensors</h1>
#{ent:mapping.keys().map(one_sensor).join("")}
<h2>Operations</h2>
<h3>Export records</h3>
<a href="export_csv.txt" target="_blank">export</a> (in new tab)
<h3>Prune older data</h3>
<form action="#{app:event_url(meta:rid,"prune_all_needed")}">
<label for="cutoff">Data older than:</label>
<select name="cutoff" id="cutoff" required>
  <option value="">Choose date</option>
#{
daysInRecord()
  .map(function(d){
    midnight = function(d){ // choose MDT or MST
      d > "2024-11-03" => "T07" |
      d > "2024-03-10" => "T06" |
                          "T07"
    }
    <<  <option value="#{d}#{midnight(d)}">#{d}</option>
>>})
  .join("")
}</select>
<button type="submit" style="cursor:pointer">Prune</button>
</form>
>>
,_headers)
    }
    cutoff_index = function(list,cutoff_date){
      find_index = function(answer,v,i){
        answer >= 0      => answer | // already found cutoff
        i%2              => answer | // temp value
        v < cutoff_date  => answer | // date before cutoff
                            i        // cutoff index
      }
      list.reduce(find_index,-1)
    }
    pruned_list = function(list,cutoff_date){
      index = cutoff_date => list.cutoff_index(cutoff_date) | 0
      sanity = (index%2==0).klog("index even?")
      sanity => list.slice(index,list.length()-1) | list
    }
    history = function(name,cutoff,_headers){
      app:html_page("sensor "+name,"",
      <<
<h1>sensor #{name}</h1>
<h2>#{ent:mapping{name}}</h2>
<table>
<tr>
<th>Timestamp</th>
<th>Temperature</th>
</tr>
#{ent:record{name}.pruned_list(cutoff).reduce(temps,"").join("")}
</table>
>>
,_headers)
    }
    LF = chr(10)
    export = function(delim){
      one_device = function(list,delims){
        tts = function(a,tt,i){
          a+(i%2==0 => tt.makeMT().ts_format() + delims | tt + LF)
        }
        list.length() => list.reduce(tts,"") | ""
      }
      hdr = ["Timestamp"].append(ent:mapping.values().reverse()).join(delim)
      lines = ent:mapping.keys().reverse().map(function(k,i){
        delims = 0.range(i).map(function(x){delim}).join("")
        ent:record{k}.one_device(delims)
      }).join("").split(LF).sort().join(LF)
      hdr
      + lines
    }
    export_tsv = function(){
      export(chr(9))
    }
    export_csv = function(){
      export(",")
    }
    export_raw = function(name){
      ent:record{name}.klog("raw")
    }
    summary = function(){
      one_sensor = function(k){
        v = ent:record.get(k)
        vlen = v.length()
        the_timestamp = v[vlen-2]
        the_time_only = the_timestamp.makeMT().ts_format().replace(re#.* #,"")
        the_temp = v[vlen-1]
        <<<tr>
<td title="#{k}">#{ent:mapping{k}}</td>
<td title="#{the_timestamp}">#{the_time_only}</td>
<td>#{the_temp}°F</td>
</tr>
>>
      }
      <<<table>
<tr><th>Location</th><th>Time</th><th>Temperature</th></tr>
#{ent:mapping.keys().map(one_sensor).join("")}
</table>
>>
    }
  }
  rule prepareChannel {
    select when io_picolabs_plan_wovyn_sensors factory_reset
      where ent:sensor_channel_id.isnull()
    wrangler:createChannel(
      ["input_from","wovyn_sensors"],
      {"allow":[{"domain":"io_picolabs_plan_wovyn_sensors","name":"heartbeat"}],"deny":[]},
      {"allow":[],"deny":[{"rid":"*","name":"*"}]}
    ) setting(channel)
    fired {
      ent:sensor_channel_id := channel.get("id")
    }
  }
  rule prepare {
    select when io_picolabs_plan_wovyn_sensors factory_reset
      where ent:record.isnull()
    fired {
      ent:record := {}
      ent:mapping := {
        "Wovyn_2BD707": "Shed",
        "Wovyn_162EB3": "Attic",
        "Wovyn_163ECD": "Kitchen",
        "Wovyn_746ABF": "Porch",
      }
    }
  }
  rule removeSensorMapping {
    select when io_picolabs_plan_wovyn_sensors sensor_not_needed
      name re#(Wovyn_[A-F0-9]{6})#
      setting(name)
    if ent:mapping.keys() >< name then
      send_directive("_redirect",{"url":settings_link()})
    fired {
      clear ent:mapping{name}
    }
  }
  rule addSensorMapping {
    select when io_picolabs_plan_wovyn_sensors sensor_needed
      name re#(Wovyn_[A-F0-9]{6})#
      location re#(.+)#
      setting(name,location)
    pre {
      new_location = {}.put(name,location)
.klog("new_location")
      new_mapping = ent:mapping
        .keys()
        .reduce(function(a,k){
            a.put(k,ent:mapping.get(k))
          },new_location)
.klog("new_mapping")
    }
    send_directive("_redirect",{"url":settings_link()})
    fired {
      ent:mapping{name} := location
    }
  }
  rule acceptHeartbeat {
    select when io_picolabs_plan_wovyn_sensors heartbeat
      eventDomain re#^wovyn.emitter$#
    pre {
      device = event:attrs{["property","name"]}
      local_name = ent:mapping{device}
      temps = event:attrs{["genericThing","data","temperature"]}
      tempF = temps.head(){"temperatureF"}
      time = time:now()
      record = ent:record{device}.defaultsTo([]).append([time,tempF])
    }
    fired {
      ent:record{device} := record
      raise io_picolabs_plan_wovyn_sensors event "temp_recorded"
        attributes {"name":local_name,"time":time.makeMT(),"temp":tempF}
    }
  }
  rule pruneList {
    select when io_picolabs_plan_wovyn_sensors prune_needed
      where ent:record.keys() >< event:attr("name")
    pre {
      device = event:attr("name")
      cutoff = event:attr("cutoff")
      new_list = ent:record{device}.pruned_list(cutoff)
    }
    fired {
      ent:record{device} := new_list
    }
  }
  rule pruneAllLists {
    select when io_picolabs_plan_wovyn_sensors prune_all_needed
      cutoff re#^(202\d-\d\d-\d\dT0\d)# setting(cutoff)
    foreach ent:mapping.keys() setting(device)
    pre {
      new_list = ent:record{device}.pruned_list(cutoff)
    }
    fired {
      ent:record{device} := new_list
    }
  }
  rule redirectBack {
    select when io_picolabs_plan_wovyn_sensors prune_all_needed
    pre {
      referrer = event:attr("_headers").get("referer") // sic
    }
    if referrer then send_directive("_redirect",{"url":referrer})
  }
}
