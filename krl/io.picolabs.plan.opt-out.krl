ruleset io.picolabs.plan.opt-out {
  meta {
    name "Right to be Forgotten"
    use module io.picolabs.plan.apps alias app
    shares opt_out
  }
  global {
    opt_out = function(_headers){
      opt_out_url = app:event_url(meta:rid,"affiliate_opts_out")
      app:html_page("manage Right to be Forgotten", "",
<<
<h1>Manage Right to be Forgotten</h1>
<p>This application allows you to opt out of the PLAN.</p>
<p>You can exercise this right by checking the box and clicking the button below.</p>
<p>This will completely delete this agent and there will be no record of anything, not even your email address.</p>
<p>Opting out cannot be undone.</p>
<p>You can of course join the network again at a later time. If you do, you will have an entirely new agent.</p>
<form action="#{opt_out_url}" onsubmit="return confirm('Are you sure?')">
<input type="checkbox" name="really">Yes, I really want to
<button type="submit">opt out</button>.
</form>
>>, _headers)
    }
  }
  rule forgetAffiliate {
    select when io_picolabs_plan_opt_out affiliate_opts_out
      really re#^.+$#
    fired {
      raise io_picolabs_plan_apps event "affiliate_opts_out"
    }
  }
  rule redirectBack {
    select when io_picolabs_plan_opt_out affiliate_opts_out
    pre {
      really = event:attrs{"really"}
      url = really => app:query_url(meta:rid,"opt_out.html") | null
    }
    if not really then send_directive("_redirect",{"url":url})
  }
}
