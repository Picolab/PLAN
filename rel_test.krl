ruleset rel_test {
  meta {
    use module io.picolabs.plan.relate alias rel
    shares established
  }
  global {
    established = function(){
      rel:relEstablished()
    }
  }
}
