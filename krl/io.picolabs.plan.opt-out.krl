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
<p>You can exercise this right by clicking the button below.</p>
<p>This will completely delete your pico and there will be no record of anything, not even your email address.</p>
<p>Opting out cannot be undone.</p>
<p>You can of course join the network again at a later time. If you do, you will have an entirely new pico.</p>
<form action="#{opt_out_url}" onsubmit="return confirm('Are you sure?')">
<input type="checkbox" name="really">Yes, I really want to
<button type="submit">opt out</button>.
</form>
>>, _headers)
    }
  }
  rule forgetAffiliate {
    select when io_picolabs_plan_opt_out:affiliate_opts_out
      really re#^.+$#
    send_directive("_redirect",{"url":meta:host})
    fired {
      raise wrangler event "ready_for_deletion"
    }
  }
  rule redirectBack {
    select when io_picolabs_plan_opt_out affiliate_opts_out
    pre {
      url = app:query_url(meta:rid,"opt_out.html")
    }
    send_directive("_redirect",{"url":url})
  }
}
