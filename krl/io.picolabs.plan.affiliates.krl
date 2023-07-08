ruleset io.picolabs.plan.affiliates {
  meta {
    use module io.picolabs.wrangler alias wrangler
    use module com.mailjet.sdk alias email
    shares lastResponse
  }
  global {
    lastResponse = function(){
      ent:lastResponse
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
      eci = meta:eci // TODO use a one-time ECI
      url = <<#{meta:host}/sky/event/#{eci}/none/io_picolabs_plan_affiliates/email_address_verified?cid=#{cid}>>
      subject = "verify your email address"
      message = "Click here to verify your email address: " + url
    }
    email:send_text(email_address,subject,message) setting(res)
    fired {
      ent:correlation{cid} := email_address
      ent:lastResponse := res
    }
  }
  rule handleEmailVerification {
    select when io_picolabs_plan_affiliates email_address_verified
      cid re#(.+)# setting(cid)
    pre {
      email_address = ent:correlation{cid}
    }
    if email_address then noop()
    fired {
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
      raise ruleset event "repo_installed" // terminal event
    }
  }
}
