src = (e) ->
  e.srcElement or e.target

pde = (e) ->
  if e.preventDefault
    e.preventDefault()
  else
    e.returnValue = false

click_get_a = (o) ->
  if o.is("a")
    o
  else if o.parent().is("a")
    o.parent()
  else
    null

loading_start = (button) ->
  button.button "loading"
  button.siblings("img.loading").show()

loading_finish = (button) ->
  button.button "reset"
  button.siblings("img.loading").hide()

checklogin = (event) ->
  unless logged
    pde event
    login.modal()
    false
  else
    true

comment_show = (json, father) ->
  comment = $.parseJSON(json)
  if comment.success
    unless father?
      target = $(".replies:first")
    else
      target = father.find(".child:first > .replies")
    show = $(JST.comment({hash: comment.hash, logged: logged, karma: comment.karma, created_at: comment.created_at, id: comment.hash.split("_").pop(), href: comment.hash.replace("_", "#"), rendered_content: comment.rendered_content}))
    target.append show
  else

comment_modify = (json) ->
  comment = $.parseJSON(json)
  if comment.success
    show = $(".comment.id_" + comment.hash + ":first")
    show.find(".md:first").html comment.rendered_content
  else

@comment_reply = (event, hash) ->
  return false  unless checklogin(event)
  s = $(src(event))
  o = click_get_a(s)
  unless $("form.comment-form.id_" + hash).length is 0
    form = $("form.comment-form.id_" + hash)
    if form.attr("action") is "/comment/new/" + hash
      form.remove()
      return false
    else
      form.remove()
      form = $("form.comment-form.cloneable").clone()
  else
    form = $("form.comment-form.cloneable").clone()
  form.attr "action", "/comment/new/" + hash
  form.removeClass "cloneable"
  form.addClass "id_" + hash
  form.find(".comment_cancel:first").click(->
    $("form.id_" + hash).remove()
  ).show()
  form.ajaxForm
    clearForm: true
    beforeSubmit: (arr, form, options) ->
      if form.find("textarea[name='comment_content']").val() is ""
        false
      else
        loading_start form.find(".comment_submit:first")
        true

    success: (data, status, xhr, form) ->
      form.remove()
      comment_show data, o.parent().parent().parent()

  o.parent().parent().parent().find(".md:first").after form
  form.find("textarea").focus()

@comment_edit = (event, hash) ->
  s = $(src(event))
  o = click_get_a(s)
  unless $("form.comment-form.id_" + hash).length is 0
    form = $("form.comment-form.id_" + hash)
    if form.attr("action") is "/comment/edit/" + hash
      form.remove()
      return false
    else
      form.remove()
      form = $("form.comment-form.cloneable").clone()
  else
    form = $("form.comment-form.cloneable").clone()
  form.attr "action", "/comment/edit/" + hash
  form.removeClass "cloneable"
  form.addClass "id_" + hash
  form.find(".comment_cancel:first").click(->
    $("form.id_" + hash).remove()
  ).show()
  form.find(".comment_submit:first").text "编辑回复"
  loading_start form.find(".comment_submit:first")
  $.get "/comment/get/" + hash, (json) ->
    comment = $.parseJSON(json)
    if comment.success
      form.find("textarea[name='comment_content']:first").val comment.content
      loading_finish form.find(".comment_submit:first")
    else
      false

  form.ajaxForm
    clearForm: true
    beforeSubmit: (arr, form, options) ->
      if form.find("textarea[name='comment_content']").val() is ""
        false
      else
        loading_start form.find(".comment_submit:first")
        true

    success: (data, status, xhr, form) ->
      form.remove()
      comment_modify data

  o.parent().parent().parent().find(".md:first").after form
  form.find("textarea").focus()

@vote = (event, hash) ->
  return false  unless checklogin(event)
  o = $(src(event))
  type = undefined
  if o.hasClass("up")
    $.post "/do/vote",
      hash: hash
      vote_type: "up"

    if o.siblings().filter(".downmod").length is 0
      type = "up"
    else
      type = "up_down"
  else if o.hasClass("upmod")
    $.post "/do/vote",
      hash: hash
      vote_type: "up"

    type = "upmod"
  else if o.hasClass("down")
    $.post "/do/vote",
      hash: hash
      vote_type: "down"

    if o.siblings().filter(".upmod").length is 0
      type = "down"
    else
      type = "down_up"
  else if o.hasClass("downmod")
    $.post "/do/vote",
      hash: hash
      vote_type: "down"

    type = "downmod"
  else
    return false
  $(".id_" + hash).each (index, Element) ->
    obj = $(Element).children(".voting")
    k = $(Element).find("span.karma:first")
    nk = undefined
    switch type
      when "up"
        up = obj.children(".up")
        nk = Number(k.html()) + 1
        up.removeClass("up").addClass "upmod"
      when "up_down"
        up = obj.children(".up")
        nk = Number(k.html()) + 2
        up.removeClass("up").addClass "upmod"
        up.siblings().filter(".downmod").removeClass("downmod").addClass "down"
      when "upmod"
        upmod = obj.children(".upmod")
        nk = Number(k.html()) - 1
        upmod.removeClass("upmod").addClass "up"
      when "down"
        down = obj.children(".down")
        nk = Number(k.html()) - 1
        down.removeClass("down").addClass "downmod"
      when "down_up"
        down = obj.children(".down")
        nk = Number(k.html()) - 2
        down.removeClass("down").addClass "downmod"
        down.siblings().filter(".upmod").removeClass("upmod").addClass "up"
      when "downmod"
        downmod = obj.children(".downmod")
        nk = Number(k.html()) + 1
        downmod.removeClass("downmod").addClass "down"
    k.html nk
    $(Element).parent().remove()  if nk < minKarma

@read = (event, hash) ->
  o = $(src(event))
  if logged and o.hasClass("trackable")
    post_entry = $(".post_detail.id_"+hash).children(".entry")
    if post_entry.hasClass("new")
      post_entry.removeClass "new"

    $.ajax
      type: "POST"
      data:
        hash: hash
      async: false
      url: "/session/add_history"

    true
  else
    false

@format_help = (event) ->
  o = $(src(event))
  target = o.parent().parent()
  if target.find(".format_help").length is 0
    target.append format_table
  else
    target.find(".format_help").remove()

@change_captcha = (event) ->
  o = $(src(event))
  form = o.parent().parent().parent().parent()
  new_session = Math.floor(Math.random() * 9000) + 1000
  form.find("input[name='captcha_session']").val new_session
  #form.find("img#captcha-image").attr "src", "//captchator.com/captcha/image/" + new_session
  form.find("img#captcha-image").attr "src", "//www.opencaptcha.com/img/" + new_session + ".jpg"

@sanction = (event, hash) ->
  o = $(src(event))
  answer = confirm("R U sure?")
  return false  unless answer
  $.post "/do/sanction",
    hash: hash
  , (data) ->
    r = $.parseJSON(data)
    if r.success
      $(".post_detail.id_" + hash).each (index, Element) ->
        k = $(Element).find("span.karma:first")
        nk = Number(k.html()) - 50
        k.html nk

      o.parent().remove()
    else

@report = (event, hash) ->
  o = $(src(event))
  report = modal.clone()
  report.find(".modal-header").append "<h3>举报</h3>"
  report_form = $("<form action='/do/report' class='form-horizontal' method='post'><div class='field-set'><input name='hash' type='hidden' value='" + hash + "'><div class='control-group'><label class='control-label' for='memo'>举报原因</label><div class='controls'><textarea class='validate-input' id='memo' name='memo' rows='2'></textarea></div></div>  <div class='form-actions'><button class='btn btn-large btn-primary' type='submit'><i class='icon-white icon-ok'></i>提交</button><button class='btn btn-large' data-dismiss='modal'><i class='icon-remove'></i>取消</button></div></div></form>").ajaxForm(
    beforeSubmit: (arr, form, options) ->
      if form.find("textarea[name='memo']").val() is ""
        false
      else
        true

    success: (data, status, xhr, form) ->
      json = $.parseJSON(data)
      o.parent().remove()  if json.success
      report.modal "hide"
  )
  report.find(".modal-body").append report_form
  report.find(".modal-footer").remove()
  report.modal()

@review = (event, hash) ->
  o = $(src(event))
  event = o.parent().parent().parent()
  switch true
    when o.hasClass("positive")
      $.post "/do/review",
        hash: hash
        approved: "yes"
      , ((data) ->
        event.remove()  if data.success
      ), "json"
    when o.hasClass("negative")
      $.post "/do/review",
        hash: hash
        approved: "no"
      , ((data) ->
        event.remove()  if data.success
      ), "json"
    else
      return false

@favourite = (event, post) ->
  return false  unless checklogin(event)
  o = $(src(event))
  target = click_get_a(o)
  fn = Number(target.find(".favourite-number").html())
  $.post "/do/favourite",
    post: post
  , ((data) ->
    if data.success
      switch data.action
        when "add_favourite"
          target.find("i").addClass "color-red"
          target.find(".favourite-number").html fn + 1
        when "delete_favourite"
          target.find("i").removeClass "color-red"
          target.find(".favourite-number").html fn - 1
        else
    else
  ), "json"

@authorize_subscription = (event, user, category) ->
  o = $(src(event))
  event = o.parent().parent().parent()
  if o.hasClass("positive")
    $.post "/do/authorize_subscription",
      user: user
      category: category
      approved: "yes"
    , ((data) ->
      event.remove()  if data.success
    ), "json"
  else if o.hasClass("negative")
    $.post "/do/authorize_subscription",
      user: user
      category: category
      approved: "no"
    , ((data) ->
      event.remove()  if data.success
    ), "json"
  else
    false

@md_preview = (event) ->
  o = $(src(event))
  target = o.parent().parent().find("textarea.md_preview")
  md = target.val()
  if typeof md is "undefined"
    target = o.parent().parent().find("textarea#post_content")
    md = target.val()
  return false  if typeof md is "undefined" or md is ""
  loading_start o
  $.post "/preview",
    content: md
  , (data) ->
    r = $.parseJSON(data)
    if r.success
      loading_finish o
      pre = $(JST.md_preview({height: target.prop("scrollHeight"), width: target.width(), content: r.rendered_content}))
      pre.insertAfter target
      target.hide()
      if o.children().size() is 0
        o.text "取消预览"
      else
        icon = o.children().first().clone()
        o.text " 取消预览"
        o.prepend icon
      o.removeAttr "onclick"
      o.prop "onclick", null
      o.off "click"
      o.on "click",
        target: target
      , md_preview_back
    else

@md_preview_back = (event) ->
  o = $(src(event))
  target = event.data.target
  target.siblings(".well.md").remove()
  target.show()
  if o.children().size() is 0
    o.text "预览"
  else
    icon = o.children().first().clone()
    o.text " 预览"
    o.prepend icon
  o.off "click"
  o.attr "onclick", "md_preview(event);"

@post_edit = (event, hash) ->
  o = $(src(event))
  form = $(".post-form.id_" + hash)
  return false  if form.is(":visible")
  form.show()
  loading_start form.find(".post_submit:first")
  $.getJSON "/post/get/" + hash, (data) ->
    if data.success
      form.find("textarea[name='post_content']").val data.content
      loading_finish form.find(".post_submit:first")

  form.ajaxForm
    beforeSubmit: (arr, form, options) ->
      if form.find("textarea[name='post_content']").val() is ""
        false
      else
        loading_start form.find(".post_submit:first")
        true

    success: (data, status, xhr, form) ->
      loading_finish form.find(".post_submit:first")
      form.hide()
      post_modify data

post_modify = (json) ->
  post = $.parseJSON(json)
  if post.success
    show = $(".post_detail." + post.id_hash)
    show.find(".md").html post.rendered_content
  else

@post_delete = (event, hash) ->
  answer = confirm("R U sure?")
  return false  unless answer
  $.post "/post/delete/" + hash, ((data) ->
    if data.success
      $(".post_detail.id_" + hash).parent().remove()
    else
  ), "json"

@category_subscribe = (event, category) ->
  return false  unless checklogin(event)
  button = $(src(event))
  $.post "/category/subscribe/" + category, ((data) ->
    if data.success
      switch data.action
        when "subscribe"
          switch data.result
            when "accept"
              button.removeClass("btn-danger").addClass "btn-inverse"
              button.html "<i class='icon-minus icon-white'></i> 离开本圈子"
            when "pending"
              button.removeClass "btn-danger"
              button.html "<i class='icon-time'></i> 请求已发送"
              button.prop("onclick", null).attr("onclick", null).off "click"
        when "unsubscribe"
          button.removeClass("btn-inverse").addClass "btn-danger"
          button.html "<i class='icon-plus icon-white'></i> 加入本圈子"
    else
  ), "json"

@expando_child = (event) ->
  o = $(src(event))
  target = o.parent().parent()
  switch true
    when o.hasClass("icon-picture")
      unless target.find(".expando_pic").length is 0
        target.find(".expando_pic").toggle()
        if target.find(".expando_pic").is(":hidden")
          o.removeClass("small-cursor").addClass "big-cursor"
          o.addClass "trackable"
        else
          o.removeClass("big-cursor").addClass "small-cursor"
          o.removeClass "trackable"
      else
        div = $(JST.expando_pic({pic: o.parent().find("a").attr("href")}))
        div.on "click", ->
          $("html, body").scrollTop o.offset().top  if o.offset().top < $(window).scrollTop()
          $(this).hide()

        target.append div
        o.removeClass("big-cursor").addClass "small-cursor"
        o.removeClass "trackable"
    when o.hasClass("icon-file")
      unless target.find(".expando_text").length is 0
        target.find(".expando_text").toggle()
        if target.find(".expando_text").is(":hidden")
          o.removeClass("small-cursor").addClass "big-cursor"
          o.addClass "trackable"
        else
          o.removeClass("big-cursor").addClass "small-cursor"
          o.removeClass "trackable"
      else
        hash = o.parent().find("a").attr("href").split("/").pop()
        $.getJSON "/post/get/" + hash, (data) ->
          if data.success
            div = $(JST.expando_text({text: data.rendered_content}))
            target.append div
            o.removeClass("big-cursor").addClass "small-cursor"
            o.removeClass "trackable"
          else
    when o.hasClass("icon-facetime-video")
      video_target = target.parentsUntil(".link").parent()
      video_target_width = video_target.width()
      if video_target.find(".expando_video").length is 0
        video_type = o.attr("data-video-source")
        video_id = o.attr("data-video-id")
        video_post_id = null
        $.each target.parent().attr("class").split(" "), (i, e) ->
          video_post_id = e.slice(3)  if e.match("id_.*")
        # FIXME: add support for non-mukio player
        div = $(JST.expando_mukio_video({vtype: video_type, vid: video_id, height: video_target_width * 0.55, width: video_target_width, cid: video_post_id}))
        video_target.append div
        o.removeClass("big-cursor").addClass "small-cursor"
        o.removeClass "trackable"
      else
        video_target.find(".expando_video").remove()
        o.removeClass("small-cursor").addClass "big-cursor"
        o.addClass "trackable"
    else
      return false

@show_comment = (event) ->
  o = $(src(event))
  comment = o.parent().parent().parent()
  comment_id = undefined
  $.each comment.attr("class").split(" "), (i, e) ->
    comment_id = e  if e.match("id_.*")

  $(".comment." + comment_id).show()
  $(".comment_hide." + comment_id).hide()

@hide_comment = (event) ->
  o = $(src(event))
  comment = o.parent().parent().parent()
  comment_id = undefined
  $.each comment.attr("class").split(" "), (i, e) ->
    comment_id = e  if e.match("id_.*")

  $(".comment." + comment_id).hide()
  $(".comment_hide." + comment_id).show()

@toggle_comment = (event) ->
  o = $(src(event))
  comment = o.parent().parent().parent()
  comment_children = comment.find(".child > .replies").first()
  switch comment_children.is(":hidden")
    when true
      comment_children.show()
      o.text "[-]"
    when false
      comment_children.hide()
      o.text "[+]"

minKarma = -10

modal = $("<div class='modal'><div class='modal-header'><button class='close' data-dismiss='modal'>×</button></div><div class='modal-body'></div><div class='modal-footer'></div></div>")

login = modal.clone()

login.find(".modal-header").append "<h3>登录</h3>"

login.find(".modal-body").append "<form action='/login' class='form-horizontal validate-form' method='post'><div class='fieldset'><div class='control-group'><label class='control-label' for='login_name'>用户名</label><div class='controls'><input class='input-large' name='login_name' type='text' value=''></div></div><div class='control-group'><label class='control-label' for='login_password'>密码</label><div class='controls'><input class='input-large' name='login_password' type='password'></div></div><div class='form-actions'><button class='btn btn-large' id='login_button' type='submit'><i class='icon-ok-sign'></i>登录</button><div class='hspace'></div><div class='hspace'></div><div class='hspace'></div><a class='btn btn-primary btn-large' href='/register'><i class='icon-white icon-user'></i>注册</a></div></div></form>"

login.find(".modal-footer").remove()

format_table = $("<div class='format_help'><table class='table table-bordered table-striped'><colgroup><col class='span4'><col class='span4'></colgroup><thead><tr><th>You Type</th><th>You See</th></tr></thead><tbody><tr><td><code>_italics_</code></td><td><em>italics</em></td></tr><tr><td><code>**bold**</code></td><td><strong>bold</strong></td></tr><tr><td><code># title #</code></td><td><strong># title #</strong></td></tr><tr><td><code>[google](http://www.google.com)</code></td><td><a href='http://www.google.com'>google</a></td></tr><tr><td><code>`未分类`</code></td><td><a href='/l/uncategoried' title='未分类'>未分类</a></td></tr><tr><td><code>``` c</code><br><code>#include &lt;stdio.h&gt;</code><br><code>int main(void) {</code><br><code>&nbsp;&nbsp;&nbsp;&nbsp;printf(\"Hello World!\");</code><br><code>&nbsp;&nbsp;&nbsp;&nbsp;return 0;</code><br><code>}</code><br><code>```</code></td><td><div class='highlight'><pre><span class='cp'>#include &lt;stdio.h&gt;</span><br><span class='kt'>int</span> <span class='nf'>main</span><span class='p'>(</span><span class='kt'>void</span><span class='p'>)</span> <span class='p'>{</span><br><span class='n'>    printf</span><span class='p'>(</span><span class='s'>\"Hello World!\"</span><span class='p'>);</span><br><span class='k'>    return</span> <span class='mi'>0</span><span class='p'>;</span><br><span class='p'>}</span></pre></div></td></tr></tbody></table></div>")

$(document).ready ->
  $.ajaxSetup cache: false
  i = 0
  while i < document.forms.length
    document.forms[i].reset()
    i++

$(document).ready ->
  $(".comment-form").ajaxForm
    clearForm: true
    beforeSubmit: (arr, form, options) ->
      if form.find("textarea[name='comment_content']").val() is ""
        false
      else
        loading_start form.find(".comment_submit:first")
        true

    success: (data, status, xhr, form) ->
      loading_finish form.find(".comment_submit:first")
      comment_show data, null

$(document).ready ->
  $(".validate-form").each (index, Element) ->
    validator = $(Element).validate(
      rules:
        name:
          required: true
          minlength: 3
          maxlength: 20

        password:
          required: true

        password_confirmation:
          required: true
          equalTo: "input[name='password']"

        email:
          required: false
          email: true

        captcha_answer:
          required: true

        login_name:
          required: true
          minlength: 3
          maxlength: 20

        login_password:
          required: true

        title:
          required: true
          maxlength: 200

        url:
          url: (element) ->
            $("input[name='type']:radio:checked").val() is "url"

          required: (element) ->
            $("input[name='type']:radio:checked").val() is "url"

        post_content:
          required: (element) ->
            $("input[name='type']:radio:checked").val() is "post_content"

        category:
          required: true
          remote:
            url: "/category/check"
            type: "post"

        present_password:
          required: true

        new_password:
          required: false

        new_password_confirm:
          required: false
          equalTo: "input[name='new_password']"

      messages:
        name:
          required: "亲节操男要有名字"
          minlength: "亲你太短了"
          maxlength: "亲你太长了"

        password:
          required: "亲添个密码吧"

        password_confirmation:
          required: "亲再添一遍吧"
          equalTo: "两遍要一样哟亲"

        email:
          email: "要填email哟"

        captcha_answer:
          required: "别忘了验证码"

        login_name:
          required: "亲节操男要有名字"
          minlength: "亲你太短了"
          maxlength: "亲你太长了"

        login_password:
          required: "亲添个密码吧"

        title:
          required: "亲给个标题吧亲"
          maxlength: "标题不能超过200个字符"

        category:
          required: "亲给个类别吧亲"
          remote: "分类不存在哟亲"

      errorElement: "span"
      errorClass: "help-inline"
      highlight: (element, errorClass) ->
        $(element).parent().parent().removeClass("success").addClass "error"

      unhighlight: (element, errorClass) ->
        $(element).parent().parent().removeClass("error").addClass "success"
    )

$(document).ready ->
  category = $(".typeahead.category")
  category_members = $(".typeahead.category_members")
  unless category.length is 0
    $.get "/category/get", ((data) ->
      if data.success
        category.typeahead source: data.names
      else
    ), "json"
  unless category_members.length is 0
    category_members.each (index, element) ->
      name = undefined
      classes = $(element).attr("class").split(/\s+/)
      $(classes).each (i, e) ->
        name = e.slice(5)  if (/^name_/).test(e)

      $.get "/category/get/" + name, ((data) ->
        if data.success
          $(element).typeahead source: data.subscribers
        else
      ), "json"

$(document).ready ->
  tooltip = $(".tooltip-lb")
  unless tooltip.length is 0
    tooltip.each (index, element) ->
      e = $(element)
      switch true
        when e.hasClass("user-info")
          e.tooltip
            placement: "top"
            title: ->
              e.attr("data-post-karma") + "点功德  " + e.attr("data-comment-karma") + "点人品"

            delay: 500

        else

