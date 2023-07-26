ruleset com.vcpnews.apod {
  meta {
    name "Astronomy Picture of the Day"
    use module io.picolabs.plan.apps alias app
    shares photo
  }
  global {
    photo = function(_headers){
      reload_url = app:event_url(meta:rid,"viewer_wants_apod")
      title = ent:apod.get("title")
      styles = <<
<style type="text/css">
img.apod { width:25%; height:25%; float:left; }
p.explanation { font-size:80%; padding:2em 400px; }
a#reload { float:right; text-decoration:none; margin:0.5em; }
</style>
>>
      app:html_page("manage Astronomy Picture of the Day", styles,
<<
<a id="reload" href="#{reload_url}" title="reload">⚙️</a>
<h1>Manage Astronomy Picture of the Day</h1>
<img class="apod" src="#{ent:apod.get("url")}" alt="#{title}" title="#{title}">
<p class="explanation">#{ent:apod.get("explanation")}</p>
<p class="explanation">#{ent:apod.get("date") || ""}</p>
<br clear="all">
<p>Credits: <a href="https://apod.nasa.gov/apod/astropix.html">Astronomy Picture of the Day</a></p>
<hr>
>>, _headers)
    }
  }
  rule checkAPOD {
    select when com_vcpnews_apod factory_reset
    pre {
      today = time:now().split("T").head()
      apod_date = ent:apod.get("date")
    }
    if apod_date.isnull() || apod_date < today then noop()
    fired {
      raise com_vcpnews_apod event "need_apod"
    }
  }
  rule getAPOD {
    select when com_vcpnews_apod need_apod
             or com_vcpnews_apod viewer_wants_apod
    pre {
      api_url = "https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY"
      apod_response = http:get(api_url)
      apod = apod_response.get("content").decode()
    }
    fired {
      ent:apod := apod
    }
  }
  rule redirectBack {
    select when com_vcpnews_apod viewer_wants_apod
    pre {
      url = app:query_url(meta:rid,"photo.html")
    }
    send_directive("_redirect",{"url":url})
  }
}
