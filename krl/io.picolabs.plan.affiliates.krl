ruleset io.picolabs.plan.affiliates {
  meta {
    use module io.picolabs.wrangler alias wrangler
    use module com.mailjet.sdk alias email
    use module html.plan alias html
    shares lastResponse, correlations,
           verifPage, confirm, expiredCID, sentPage, afterVerif
  }
  global {
    lastResponse = function(){
      ent:lastResponse
    }
    correlations = function(){
      ent:correlation || {}
    }
    sent_paragraph = <<
<p>
We have sent you an email message from:
<span class="from-stuff" style='font-family:"Google Sans", Roboto, RobotoDraft, Helvetica, Arial, sans-serif'>
<span class="from-name" style="font-size:0.875rem;font-weight:bold;color:rgb(31,31,31)">Pico Labs</span>
<span class="from-email" style="font-size:0.75rem;color:rgb(94,94,94)">picolabsaffiliatenetwork@gmail.com</span>
<span class="from-via" style="font-size:0.75rem;color:rgb(94,94,94)">
<a target="_blank" href="https://support.google.com/mail/answer/1311182?hl=en"
 style="color: rgb(34,34,34);">via</a>
bnc3.mailjet.com</span>
</span>
</p>
>>
    verifPage = function(cid,_headers){
      resend_url = <<#{meta:host}/sky/event/#{meta:eci}/none/io_picolabs_plan_affiliates/need_verification_email_message>>
      html:header("email verification", "", _headers)
      + <<
<h1>Verification email message sent</h1>
#{sent_paragraph}
<p>
Didn't receive it?
</p>
<ul>
<li>Wait. Sometimes it takes a couple of minutes to arrive.</li>
<li>Check your spam folder.</li>
<li>Have us <a href="#{resend_url}?cid=#{cid}">send it again</a>.</li>
</ul>
>>
      + html:footer()
    }
    expiredCID = function(_headers){
      html:header("verification expired", "", _headers)
      + <<
<h1>Verification email message expired</h1>
<p>
Please return to the
<a href="https://PLAN.picolabs.io/">main page</a>
and submit your email address again.
</p>
>>
      + html:footer()
    }
    sentPage = function(_headers){
      html:header("link sent", "", _headers)
      + <<
<h1>Link to your personal agent</h1>
#{sent_paragraph}<p>
The link it contains will send you directly to your personal agent,
on its Manage applications page.
</p>
<p>
Didn't receive it?
</p>
<ul>
<li>Wait. Sometimes it takes a couple of minutes to arrive.</li>
<li>Check your spam folder.</li>
<li>Please return to the
<a href="https://PLAN.picolabs.io/">main page</a>
and submit your email address again.</li>
</ul>
>>
      + html:footer()
    }
    afterVerif = function(child_eci,_headers){
      childRIDs = child_eci => wrangler:picoQuery(
        child_eci,"io.picolabs.wrangler","installedRIDs") | []
      appsRID = "io.picolabs.plan.apps"
      hasRID = childRIDs >< appsRID
      url = hasRID => wrangler:picoQuery(
        child_eci,appsRID,"apps_login_url")+"?request_method=GET" | null
      html:header("After Verification", "", _headers)
      + <<
<h1>After Verification</h1>
<p>
We see that you control this email address.
</p>
<p>
Here is a one-time link to your personal agent's
<a href="#{url}">Manage applications</a>
page.
</p>
<p>
When you see the page, you can bookmark it for future reference.
</p>
>>
      + html:footer()
    }
    confirm = function(cid,_headers){
      url = <<#{meta:host}/sky/event/#{meta:eci}/none/io_picolabs_plan_affiliates/email_address_verified>>
      html:header("Confirmation", "", _headers)
      + <<
<h1>Confirmation</h1>
<p>Please confirm that you wish to own/control a personal agent.</p>
<form method="POST" action="#{url}">
<input type="hidden" name="cid" value="#{cid}">
<input type="hidden" name="request_method" value="POST">
<button type="submit">Confirm</button>
</form>
>>
      + html:footer()
    }
  }
  rule validateEmailSubmission {
    select when io_picolabs_plan_affiliates email_address_submitted
      email_address re#^([\w\d.%+-]+@[\w\d.-]+\.[a-zA-Z]+)#
      setting(email_address)
    pre {
      referrer = event:attrs{["_headers","referer"]} //sic
      expected = referrer.match(re#^https://plan.picolabs.io/#i)
    }
    if expected then noop()
    fired {
      raise io_picolabs_plan_affiliates event "email_of_affiliate" attributes event:attrs
    }
  }
  rule checkForReturningAffiliate {
    select when io_picolabs_plan_affiliates email_of_affiliate
      email_address re#^([\w\d.%+-]+@[\w\d.-]+\.[a-zA-Z]+)#
      setting(email_address)
    pre {
      matches = function(c){c{"name"}==email_address}
      child = wrangler:children().filter(matches).head()
    }
    if child then noop()
    fired {
      raise io_picolabs_plan_affiliates event "returning_affiliate" attributes child
    } else {
      raise io_picolabs_plan_affiliates event "new_affiliate_request" attributes event:attrs
    }
  }
  rule notifyReturningAffiliate {
    select when io_picolabs_plan_affiliates returning_affiliate
    pre {
      email_address = event:attrs.get("name")
      child_eci = event:attrs.get("eci")
      appsRID = "io.picolabs.plan.apps"
      childRIDs = child_eci => wrangler:picoQuery(
        child_eci,"io.picolabs.wrangler","installedRIDs") | []
      hasRID = childRIDs >< appsRID
      url = hasRID => wrangler:picoQuery(
        child_eci,appsRID,"apps_login_url") | null
      is_here = "Your personal agent is here: " + url
      sent_url = <<#{meta:host}/c/#{meta:eci}/query/#{meta:rid}/sentPage.html>>
    }
    if url then every {
      email:send_text(email_address,"your personal agent",is_here) setting(res)
      send_directive("_redirect",{"url":sent_url})
    }
    fired {
      ent:lastResponse := res
    } 
  }
  rule verifyNewAffiliateRequest {
    select when io_picolabs_plan_affiliates new_affiliate_request
    pre {
      email_address = event:attrs.get("email_address")
      cid = random:uuid()
    }
    fired {
      ent:correlation{cid} := email_address
      raise io_picolabs_plan_affiliates event "need_verification_email_message"
        attributes {"cid":cid}
    }
  }
  rule sendEmailVerificationMessage {
    select when io_picolabs_plan_affiliates need_verification_email_message
    pre {
      cid = event:attrs.get("cid")
      email_address = ent:correlation.get(cid)
      eci = meta:eci // TODO use a one-time ECI
      url = <<#{meta:host}/sky/event/#{eci}/none/io_picolabs_plan_affiliates/email_address_verified?cid=#{cid}&request_method=GET>>
      subject = "verify your email address"
      message = "Click here to verify your email address: " + url
      verif_url = <<#{meta:host}/c/#{meta:eci}/query/#{meta:rid}/verifPage.html?cid=#{cid}>>
    }
    if email_address then every {
      email:send_text(email_address,subject,message) setting(res)
      send_directive("_redirect",{"url":verif_url})
    }
    fired {
      ent:lastResponse := res
    } else {
      raise io_picolabs_plan_affiliates event "expired_cid"
    }
  }
  rule displayExpiredPage {
    select when io_picolabs_plan_affiliates expired_cid
    pre {
      expired_url = <<#{meta:host}/c/#{meta:eci}/query/#{meta:rid}/expiredCID.html>>
    }
    send_directive("_redirect",{"url":expired_url})
  }
  rule ignoreGET {
    select when io_picolabs_plan_affiliates email_address_verified
      request_method re#^GET$#
    pre {
      cid = event:attrs.get("cid")
      confirm_url = <<#{meta:host}/c/#{meta:eci}/query/#{meta:rid}/confirm.html?cid=#{cid}>>
    }
    send_directive("_redirect",{"url":confirm_url})
    fired {
      last
    }
  }
  rule handleEmailVerification {
    select when io_picolabs_plan_affiliates email_address_verified
      cid re#(.+)# setting(cid)
    pre {
      email_address = ent:correlation{cid}
.klog("email_address")
    }
    if email_address then noop()
    fired {
      clear ent:correlation{cid}
      raise wrangler event "new_child_request" attributes
        event:attrs.put("name",email_address)
    } else {
      raise io_picolabs_plan_affiliates event "expired_cid"
    }
  }
  rule reactToChildCreation {
    select when wrangler:new_child_created
    pre {
      child_eci = event:attrs.get("eci")
      after_verif_url = <<#{meta:host}/c/#{meta:eci}/query/#{meta:rid}/afterVerif.html>>
        + "?child_eci=" + child_eci
    }
    if child_eci then every {
      event:send({"eci":child_eci,
        "domain":"wrangler","type":"install_ruleset_request",
        "attrs":{"absoluteURL": meta:rulesetURI,"rid":"io.picolabs.pds"}
      })
      event:send({"eci":child_eci,
        "domain":"wrangler","type":"install_ruleset_request",
        "attrs":{"absoluteURL": meta:rulesetURI,"rid":"html.plan"}
      })
      event:send({"eci":child_eci,
        "domain":"wrangler","type":"install_ruleset_request",
        "attrs":{"absoluteURL": meta:rulesetURI,"rid":"io.picolabs.plan.apps"}
      })
      send_directive("_redirect",{"url":after_verif_url})
    }
    fired {
      raise ruleset event "rulesets_installed_for_affiliate" // terminal event
    }
  }
}
