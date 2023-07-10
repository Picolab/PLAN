ruleset io.picolabs.plan.affiliates {
  meta {
    use module io.picolabs.wrangler alias wrangler
    use module com.mailjet.sdk alias email
    use module html.plan alias html
    shares lastResponse, correlations, verifPage
  }
  global {
    lastResponse = function(){
      ent:lastResponse
    }
    correlations = function(){
      ent:correlation.encode() || {}
    }
    verifPage = function(cid,_headers){
      resend_url = <<#{meta:host}/sky/event/#{meta:eci}/none/io_picolabs_plan_affiliates/need_verification_email_message>>
      html:header("email verification", "", _headers)
      + <<
<h1>Verification email message sent</h1>
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
<p>
Please click on the link it contains,
in order to verify that you control the email address.
</p>
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
        child_eci,appsRID,"app_anchor",{"rid":appsRID}) | null
      is_here = "Your pico is here: " + url
    }
    if url then
      email:send_text(email_address,"your pico",is_here) setting(res)
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
      url = <<#{meta:host}/sky/event/#{eci}/none/io_picolabs_plan_affiliates/email_address_verified?cid=#{cid}>>
      subject = "verify your email address"
      message = "Click here to verify your email address: " + url
      verif_url = <<#{meta:host}/c/#{meta:eci}/query/#{meta:rid}/verifPage.html?cid=#{cid}>>
    }
    every {
      email:send_text(email_address,subject,message) setting(res)
      send_directive("_redirect",{"url":verif_url})
    }
    fired {
      ent:lastResponse := res
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
    }
  }
  rule reactToChildCreation {
    select when wrangler:new_child_created
    pre {
      child_eci = event:attr("eci")
    }
    if child_eci then every {
      event:send({"eci":child_eci,
        "domain":"wrangler","type":"install_ruleset_request",
        "attrs":{"absoluteURL": meta:rulesetURI,"rid":"html.plan"}
      })
      event:send({"eci":child_eci,
        "domain":"wrangler","type":"install_ruleset_request",
        "attrs":{"absoluteURL": meta:rulesetURI,"rid":"io.picolabs.plan.apps"}
      })
    }
    fired {
      raise ruleset event "rulesets_installed_for_affiliate" // terminal event
    }
  }
}
