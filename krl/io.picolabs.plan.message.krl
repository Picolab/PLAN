ruleset io.picolabs.plan.message {
  meta {
    name "BasicMessages"
    use module io.picolabs.plan.apps alias app
    use module io.picolabs.did-o alias dcv2
    use module didcomm-v2.basicmessage alias basicmessage
    shares message
  }
  global {
    message = function(did,_headers){
      name = wrangler:picoQuery(did,"io.picolabs.plan.profile","name",{})
      app:html_page("BasicMessages", "",
<<
<h1>BasicMessages</h1>
<h2>For DID #{did.elide()}</h2>
#{name => <<<p>Over connection you have with #{name}.</p>
>> | ""}
>>, _headers)
    }
    elide = function(did){
      did.length() < 30 => did
                         | did.substr(0,25) + "…"
    }
  }
}
