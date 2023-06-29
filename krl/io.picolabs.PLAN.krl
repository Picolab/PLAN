ruleset io.picolabs.PLAN {
  meta {
    use module io.picolabs.wrangler alias wrangler
  }
  global {
  }
  rule enrollAffiliate {
    select when PLAN email_address_submitted
      email_address re#^([\w\d.%+-]+@[\w\d.-]+\.[a-zA-Z]+)#
      setting(email_address)
    pre {
      matches = function(c){c{"name"}==email_address}
      child = wrangler:children().filter(matches).head()
    }
    if not child then noop()
  }
}
