# vim: ft=coffee
click_get_a = (o) ->
    return o if o.is "a"
    return o.parent if o.parent.is "a"
    null
