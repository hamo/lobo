/*
 *
 * Application-related Javascript code
 * This file is just for development
 * On production, This file should be compiled 
 * and renamed to application.min.js
 *
 */

/*
 *
 * var define
 *
 */
var minKarma = -10;

var modal = $("<div class='modal'><div class='modal-header'><button class='close' data-dismiss='modal'>×</button></div><div class='modal-body'></div><div class='modal-footer'></div></div>");

// Generate login modal
var login = modal.clone();
login.find(".modal-header").append("<h3>登录</h3>");
login.find(".modal-body").append("<form action='/login' class='form-horizontal validate-form' method='post'><div class='fieldset'><div class='control-group'><label class='control-label' for='login_name'>用户名</label><div class='controls'><input class='input-large' name='login_name' type='text' value=''></div></div><div class='control-group'><label class='control-label' for='login_password'>密码</label><div class='controls'><input class='input-large' name='login_password' type='password'></div></div><div class='form-actions'><button class='btn btn-large' id='login_button' type='submit'><i class='icon-ok-sign'></i>登录</button><div class='horizontal-space'></div><a class='btn btn-primary btn-large' href='/register'><i class='icon-white icon-user'></i>注册</a></div></div></form>");
login.find(".modal-footer").remove();

// Generate markdown syntax table
var format_table = $("<div class='format_help'><table class='table table-bordered table-striped'><colgroup><col class='span4'><col class='span4'></colgroup><thead><tr><th>You Type</th><th>You See</th></tr></thead><tbody><tr><td><code>_italics_</code></td><td><em>italics</em></td></tr><tr><td><code>**bold**</code></td><td><strong>bold</strong></td></tr><tr><td><code># title #</code></td><td><strong># title #</strong></td></tr><tr><td><code>[google](http://www.google.com)</code></td><td><a href='http://www.google.com'>google</a></td></tr><tr><td><code>`未分类`</code></td><td><a href='/l/uncategoried' title='未分类'>未分类</a></td></tr></tbody></table></div>");

/*
 *
 * Base functions
 *
 */
function src(e) {
    return e.srcElement || e.target;
}

function pde(e) {//Function to prevent Default Events
    if(e.preventDefault)
        e.preventDefault();
    else
        e.returnValue = false;
}

function loading_start(button) {
    button.button('loading');
    button.siblings('img.loading').show();
}

function loading_finish(button) {
    button.button('reset');
    button.siblings('img.loading').hide();
}

function checklogin(event) {
    if (logged)
	return true;
    else {
	pde(event);
	login.modal();
	return false;
    }
}

$(document).ready(function () {
    $.ajaxSetup({cache: false});
    for (i = 0; i < document.forms.length; i++) {
        document.forms[i].reset();
    }
});

/*
 *
 * Comment-related javascript functions
 *
 */
$(document).ready(function() {
    $('.comment-form').ajaxForm({
	clearForm: true,
	beforeSubmit: function(arr, form, options){
            if (form.find("textarea[name='comment_content']").val() == "") {
		return false;
            } else {
		loading_start(form.find('.comment_submit:first'));
		return true;
            }
	},
	success: function(data, status, xhr, form){
            loading_finish(form.find('.comment_submit:first'));
            comment_show(data, null);
	}
    });
})

function comment_show(json, father){
    var comment = $.parseJSON(json);
    if (comment.success) {
	if (father == null) {
	    var target = $(".replies:first");
	} else {
	    var target = father.find(".child:first > .replies");
	}

	var voting = $("<div>", {'class': 'voting'});
	voting.append($("<div>", {'class': "arrow sprite upmod", onclick: "vote(event, '"+comment.hash+"');"}));
	voting.append($("<div>", {'class': 'arrow sprite down', onclick: "vote(event, '"+comment.hash+"');"}));

	var detail = $("<div>", {'class': 'comment_detail entry'});

	var ac_karma = $("<div>", {'class': 'action'}).append($("<i>", {'class': 'icon-arrow-up'})).append(" ").append($("<span>", {'class': 'karma', 'text': comment.karma})).append(" ");
	var ac_time = $("<div>", {'class': 'action'}).append($("<i>", {'class': 'icon-time'})).append(" ").append(comment.created_at).append(" ");
	var ac_link = $("<div>", {'class': 'action'}).append($("<i>", {'class': 'icon-link'})).append(" ").append($("<a>", {href: "/p/"+comment.hash.replace("_","#"), text: "链接"})).append(" ");
	var ac_reply = $("<div>", {'class': 'action'}).append($("<a>", {onclick: "comment_reply(event, '"+comment.hash+"');", html: "<i class='icon-comment-alt'></i> 回复 "}));
	var ac_edit = $("<div>", {'class': 'action'}).append($("<a>", {onclick: "comment_edit(event, '"+comment.hash+"');", html: "<i class='icon-edit'></i> 编辑 "}));

	detail.append($("<div>", {'class': 'tagline'}).append($("<strong>").append($("<a>", {href: '/u/'+logged, html: logged}))).append(ac_karma).append(ac_time).append(ac_link).append(ac_reply).append(ac_edit));
	detail.append($("<div>", {'class': 'md current_user', html: comment.rendered_content}));
	detail.append($("<div>", {'class': 'child'}).append($("<div>", {'class': 'replies'})));

	var show = $("<div>", {'class': "comment "+comment.id_hash, id: comment.hash.split('_').pop()});
	show.append(voting);
	show.append(detail);

	var clear = $("<div>", {'class': 'clearleft'});

	target.prepend(clear);
	target.prepend(show);
	
    } else {

    }
}

function comment_modify(json) {
    var comment = $.parseJSON(json);
    if (comment.success) {
	var show = $('.comment.id_'+comment.hash+':first');
//	show.find('.tagline').html("").append($("<strong>").append($("<a>", {href: '/#', html: logged}))).append(" 发表于"+comment.updated_at+" | ").append($("<span>", {'class': 'karma', html: comment.karma})).append(" 点人品");
	show.find('.md:first').html(comment.rendered_content);
    } else {
	//FIXME
    }
}

function comment_reply(event, hash) {
    if (!checklogin(event))
	return false;
    var o = $(src(event));
    if ($('form.comment-form.id_'+hash).length != 0) {
	var form = $('form.comment-form.id_'+hash);
	if(form.attr("action") == "/comment/new/"+hash) {
	    form.remove();
	    return false;
	} else {
	    form.remove();
	    var form = $("form.comment-form.cloneable").clone();
	}
    } else {
	var form = $("form.comment-form.cloneable").clone();
    }
    form.attr("action", "/comment/new/"+hash);
    form.removeClass("cloneable");
    form.addClass("id_"+hash);
    form.find('.comment_cancel:first').click(function() {
	$('form.id_'+hash).remove();
    }).show();
    form.ajaxForm({
	clearForm: true,
	beforeSubmit: function(arr, form, options){
	    if (form.find("textarea[name='comment_content']").val() == "") {
		return false;
	    } else {
		loading_start(form.find('.comment_submit:first'));
		return true;
	    }
	},
	success: function(data, status, xhr, form){
	    form.remove();
	    comment_show(data, o.parent().parent().parent());
	}
    });
    o.parent().parent().parent().find(".md:first").after(form);
    form.find("textarea").focus();
}

function comment_edit(event, hash) {
    var o = $(src(event));
    if ($('form.comment-form.id_'+hash).length != 0) {
	var form = $('form.comment-form.id_'+hash);
	if(form.attr("action") == "/comment/edit/"+hash) {
	    form.remove();
	    return false;
	} else {
	    form.remove();
	    var form = $("form.comment-form.cloneable").clone();
	}
    } else {
	var form = $("form.comment-form.cloneable").clone();
    }
    form.attr("action", "/comment/edit/"+hash);
    form.removeClass("cloneable");
    form.addClass("id_"+hash);
    form.find('.comment_cancel:first').click(function() {
	$('form.id_'+hash).remove();
    }).show();
    form.find('.comment_submit:first').text("编辑回复");
    loading_start(form.find('.comment_submit:first'));
    $.get("/comment/get/"+hash, function(json){
	var comment = $.parseJSON(json);
	if (comment.success) {
	    form.find("textarea[name='comment_content']:first").val(comment.content);
	    loading_finish(form.find('.comment_submit:first'));
	} else {
	    // FIXME
	    return false;
	}
    });

    form.ajaxForm({
	clearForm: true,
	beforeSubmit: function(arr, form, options){
	    if (form.find("textarea[name='comment_content']").val() == "") {
		return false;
	    } else {
		loading_start(form.find('.comment_submit:first'));
		return true;
	    }
	},
	success: function(data, status, xhr, form){
	    form.remove();
	    comment_modify(data);
	}
    });
    o.parent().parent().parent().find(".md:first").after(form);
    form.find("textarea").focus();
}
/*
 *
 * Validate Form
 *
 */
$(document).ready(function() {
    $(".validate-form").each(function(index, Element){
	var validator = $(Element).validate({
	    rules:{
		name: {
		    required: true,
		    minlength: 3,
		    maxlength: 20
		},
		password: {
		    required: true
		},
		password_confirmation: {
		    required: true,
		    equalTo: "input[name='password']"
		},
		email: {
		    required: false,
		    email: true
		},
		captcha_answer: {
		    required: true
		},
		login_name: {
		    required: true,
		    minlength: 3,
		    maxlength: 20
		},
		login_password: {
		    required: true
		},
		title: {
		    required: true
		},
		url: {
		    url: function(element) {
			return $("input[name='type']:radio:checked").val() == "url";
		    },
		    required: function(element) {
			return $("input[name='type']:radio:checked").val() == "url";
		    }
		},
		content: {
		    required: function(element) {
			return $("input[name='type']:radio:checked").val() == "content";
		    }
		},
		category: {
		    required: true
		},
		present_password: {
		    required: true
		},
		new_password: {
		    required: false
		},
		new_password_confirm: {
		    required: false,
		    equalTo: "input[name='new_password']"
		}
	    },
	    messages: {
		name:{
		    required:"亲节操男要有名字",
		    minlength: "亲你太短了",
		    maxlength: "亲你太长了"
		},
		password: {
		    required: "亲添个密码吧"
		},
		password_confirmation: {
		    required: "亲再添一遍吧",
		    equalTo: "两遍要一样哟亲"
		},
		email: {
		    email: "要填email哟"
		},
		captcha_answer: {
		    required: "别忘了验证码"
		},

		login_name:{
		    required:"亲节操男要有名字",
		    minlength: "亲你太短了",
		    maxlength: "亲你太长了"
		},
		login_password: {
		    required: "亲添个密码吧"
		},
		title: {
		    required: "亲给个标题吧亲"
		},
		category: {
		    required: "亲给个类别吧亲"
		}
	    },
	    errorElement: "span",
	    errorClass: "help-inline",
	    highlight: function(element, errorClass) {
		$(element).parent().parent().removeClass('success').addClass('error');
	    },
	    unhighlight: function (element, errorClass) {
		$(element).parent().parent().removeClass('error').addClass('success');
	    }
	});
    });
})

/*
 *
 * others functions
 *
 */
function vote(event, hash) {
    if(!checklogin(event))
	return false;
    var o = $(src(event));
    var type;
    if(o.hasClass("up")){
	$.post("/do/vote", {hash: hash, vote_type: 'up'});
	if(o.siblings().filter(".downmod").length==0)
	    type = "up";
	else
	    type = "up_down";
    } else if (o.hasClass("upmod")){
	$.post("/do/vote", {hash: hash, vote_type: 'up'});
	type = "upmod";
    } else if (o.hasClass("down")){
	$.post("/do/vote", {hash: hash, vote_type: 'down'});
	if(o.siblings().filter(".upmod").length==0)
	    type = "down";
	else 
	    type = "down_up";
    } else if (o.hasClass("downmod")){
	$.post("/do/vote", {hash: hash, vote_type: 'down'});
	type = "downmod";
    } else {
	return false;
    }
    $(".id_"+hash).each(function(index, Element){
	var obj = $(Element).children(".voting");
	var k = $(Element).find("span.karma:first");
	var nk;
	switch (type){
	case "up":
	    var up = obj.children(".up");
	    nk = Number(k.html())+1;
	    up.removeClass("up").addClass("upmod");
	    break;
	case "up_down":
	    var up = obj.children(".up");
	    nk = Number(k.html())+2;
	    up.removeClass("up").addClass("upmod");
	    up.siblings().filter(".downmod").removeClass("downmod").addClass("down");
	    break;
	case "upmod":
	    var upmod = obj.children(".upmod");
	    nk = Number(k.html())-1;
	    upmod.removeClass("upmod").addClass("up");
	    break;
	case "down":
	    var down = obj.children(".down");
	    nk = Number(k.html())-1;
	    down.removeClass("down").addClass("downmod");
	    break;
	case "down_up":
	    var down = obj.children(".down");
	    nk = Number(k.html())-2;
	    down.removeClass("down").addClass("downmod");
	    down.siblings().filter(".upmod").removeClass("upmod").addClass("up");
	    break;
	case "downmod":
	    var downmod = obj.children(".downmod");
	    nk = Number(k.html())+1;
	    downmod.removeClass("downmod").addClass("down");
	    break;
	}
	k.html(nk);
	if(nk < minKarma) {
	    $(Element).parent().remove();
	}
    });
}

function read(event, hash) {
    var o = $(src(event));
    if(logged && o.hasClass('trackable')) {
	$.ajax({
	    type: "POST",
	    data: {hash: hash},
	    async: false,
	    url: "/session/add_history"
	});
	return true;
    } else {
	return false;
    }
}

function format_help(event) {
    var o = $(src(event));
    var target = o.parent().parent();
    if (target.find('.format_help').length == 0)
	target.append(format_table);
    else
	target.find('.format_help').remove();
}

function change_captcha(event) {
    var o = $(src(event));
    var form = o.parent().parent().parent().parent();
    var new_session = Math.floor(Math.random()*9000) + 1000;
    form.find("input[name='captcha_session']").val(new_session);
    form.find("img#captcha-image").attr("src","http://captchator.com/captcha/image/"+new_session);
}

function sanction(event, hash) {
    var o = $(src(event));
    var answer = confirm("R U sure?");
    if (!answer)
	return false;
    $.post("/do/sanction", 
	   {hash: hash}, 
	   function(data) {
	       var r = $.parseJSON(data);
	       if (r.success) {
		   $(".post_detail.id_"+hash).each(function(index, Element){
		       var k = $(Element).find("span.karma:first");
		       var nk = Number(k.html())-50;
		       k.html(nk);
		   });
		   o.parent().remove();
	       } else {
		   //FIXME
	       }
	   });
}

function report(event, hash) {
    var o = $(src(event));
    var report = modal.clone();
    report.find(".modal-header").append("<h3>举报</h3>");
    report_form = $("<form action='/do/report' class='form-horizontal' method='post'><div class='field-set'><input name='hash' type='hidden' value='"+hash+"'><div class='control-group'><label class='control-label' for='memo'>举报原因</label><div class='controls'><textarea class='validate-input' id='memo' name='memo' rows='2'></textarea></div></div>  <div class='form-actions'><button class='btn btn-large btn-primary' type='submit'><i class='icon-white icon-ok'></i>提交</button><button class='btn btn-large' data-dismiss='modal'><i class='icon-remove'></i>取消</button></div></div></form>").ajaxForm({
	beforeSubmit: function(arr, form, options){
	    if (form.find("textarea[name='memo']").val() == "") {
		return false;
	    } else {
		return true;
	    }
	},
	success: function(data, status, xhr, form){
	    var json = $.parseJSON(data);
	    if(json.success)
		o.parent().remove();
	    report.modal('hide');
	}
    });

    report.find(".modal-body").append(report_form);
    report.find(".modal-footer").remove();
    report.modal();
}

function review(event, hash) {
    var o = $(src(event));
    var event = o.parent().parent().parent();
    switch(true) {
    case o.hasClass('positive'):
	$.post('/do/review',
	       {hash: hash, approved: 'yes'},
	       function(data) {
		   if(data.success) {
		       event.remove();
		   }
	       },
	       "json");
	break;
    case o.hasClass('negative'):
	$.post('/do/review',
	       {hash: hash, approved: 'no'},
	       function(data) {
		   if(data.success) {
		       event.remove();
		   }
	       },
	       "json");
	break;
    default:
	return false;
	break;
    }
}

function favourite(event, post) {
    if (!checklogin(event))
	return false;
    var o = $(src(event));
    if(!o.is("a")) {
	var target = o.parent();
    } else {
	var target = o;
    }
    var fn = Number(target.find(".favourite-number").html());
    $.post("/do/favourite",
	   {post: post},
	   function(data) {
	       if(data.success) {
		   switch(data.action) {
		   case "add_favourite":
		       target.find("i").addClass("color-red");
		       target.find(".favourite-number").html(fn+1);
		       break;
		   case "delete_favourite":
		       target.find("i").removeClass("color-red");
		       target.find(".favourite-number").html(fn-1);
		       break;
		   default:
		       break;
		   }
	       } else {
		   //FIXME
	       }
	   },
	   "json");
}


function authorize_subscription(event, user, category) {
    var o = $(src(event));
    var event = o.parent().parent().parent();
    if(o.hasClass('positive')){
	$.post('/do/authorize_subscription',
	       {user: user, category: category, approved: 'yes'},
	       function(data) {
		   if(data.success) {
		       event.remove();
		   }
	       },
	       "json");
    } else if(o.hasClass('negative')){
	$.post('/do/authorize_subscription',
	       {user: user, category: category, approved: 'no'},
	       function(data) {
		   if(data.success) {
		       event.remove();
		   }
	       },
	       "json");
    } else {
	return false;
    }
}

function md_preview(event) {
    var o = $(src(event));
    var loading = o.parent().find(".comment_loading");
    var md = o.parent().parent().find("textarea.md_preview").val();
    if (typeof md === "undefined" || md == "")
	return false;
    loading_start(o);
    $.post("/preview",
	   {content: md},
	   function(data) {
	       var r = $.parseJSON(data);
	       if (r.success) {
		   loading_finish(o);
		   var preview = modal.clone();
		   preview.find(".modal-header").append("<h3>预览</h3>");
		   preview.find(".modal-body").append("<div class='md'>"+r.rendered_content+"</div>");
		   preview.find(".modal-footer").remove();
		   preview.modal();
	       } else {
		   // FIXME
	       }
	   }
	  );
}

function post_edit(event, hash) {
    var o = $(src(event));
    var form = $(".post-form.id_"+hash);
    if (form.is(":visible"))
	return false;
    form.show();
    loading_start(form.find('.post_submit:first'));
    $.getJSON('/post/get/' + hash,
	  function(data) {
	      if (data.success) {
		  form.find("textarea[name='post_content']").val(data.content);
		  loading_finish(form.find('.post_submit:first'));
	      }
	  });
    form.ajaxForm({
	beforeSubmit: function(arr, form, options){
	    if (form.find("textarea[name='post_content']").val() == "") {
		return false;
	    } else {
		loading_start(form.find('.post_submit:first'));
		return true;
	    }
	},
	success: function(data, status, xhr, form){
	    loading_finish(form.find('.post_submit:first'));
	    form.hide();
	    post_modify(data);
	}
    });
}

function post_modify(json) {
    var post = $.parseJSON(json);
    if (post.success) {
	var show = $('.post_detail.'+post.id_hash);
	show.find('.md').html(post.rendered_content);
    } else {
	//FIXME
    }
}

function post_delete(event, hash) {
    var answer = confirm("R U sure?");
    if (!answer)
	return false;
    $.post('/post/delete/'+hash,
	   function(data) {
	       if (data.success) {
		   $('.post_detail.id_'+hash).parent().remove();
	       } else {
		   //FIXME
	       }
	   },
	   "json");
}

/*
 *
 * typeahead
 *
 */
$(document).ready(function () {
    var category = $('.typeahead.category');
    var category_members = $('.typeahead.category_members');
    
    if (category.length != 0) {
	category.parent().parent().parent().find("button[type='submit']").attr("disabled", true);
	$.get("/category/get",
	      function(data) {
		  if(data.success) {
		      category.typeahead({source: data.names});
		      category.parent().parent().parent().find("button[type='submit']").removeAttr("disabled");
		  } else {
		      //FIXME
		  }
	      },
	      "json");
    }

    if (category_members.length != 0) {
	category_members.each(function(index, element){
	    var name;
	    var classes = $(element).attr('class').split(/\s+/);
	    $(classes).each(function(i, e){
		if ((/^name_/).test(e)) {
		    name = e.slice(5);
		}
	    });
	$.get("/category/get/"+name,
	      function(data) {
		  if(data.success) {
		      $(element).typeahead({source: data.subscribers});
		  } else {
		      //FIXME
		  }
	      },
	      "json");
	});
    }
});

/*
 *
 * tooltip
 *
 */
$(document).ready(function () {
    var tooltip = $(".tooltip-lb");

    if(tooltip.length != 0) {
	tooltip.each(function(index, element) {
	    var e = $(element);
	    switch(true) {
	    case e.hasClass('user-info'):
		e.tooltip({
		    placement: 'top',
		    title: function() {
			return e.attr("data-post-karma")+"点功德  "+e.attr("data-comment-karma")+"点人品";
		    },
                    delay: 500
		});
		break;
	    default:
		break;
	    }
	});
    }
});

/*
 *
 * Category functions
 *
 */
function category_subscribe(event, category) {
    if (!checklogin(event))
	return false;
    var button = $(src(event));
    $.post("/category/subscribe/"+category,
	   function(data) {
	       if(data.success) {
		   switch(data.action) {
		   case 'subscribe':
		       switch(data.result) {
		       case 'accept':
			   button.removeClass('btn-danger').addClass('btn-inverse');
			   button.html("<i class='icon-minus icon-white'></i> 离开本圈子");
			   break;
		       case 'pending':
			   button.removeClass('btn-danger');
			   button.html("<i class='icon-time'></i> 请求已发送");
			   button.prop("onclick", null).attr("onclick", null).off('click');
			   break;
		       }
		       break;
		   case 'unsubscribe':
		       button.removeClass('btn-inverse').addClass('btn-danger');
		       button.html("<i class='icon-plus icon-white'></i> 加入本圈子");
		       break;
		   }
	       } else {
		   //FIXME
	       }
	   },
	   "json"
	  );
}

function expando_child(event) {
    var o = $(src(event));
    var target = o.parent().parent();
    switch(true) {
    case o.hasClass('icon-picture'):
	if (target.find(".expando_pic").length != 0) {
	    target.find(".expando_pic").toggle();
	} else {
	    var pic = o.parent().find('a').attr('href');
	    var div = $("<div class='expando_pic'>").append($("<img>").attr('src', pic));
	    div.on("click", function() {
		if (o.offset().top < $(window).scrollTop()) {
		    $('html, body').scrollTop(o.offset().top);
		}
		$(this).hide();
	    });
	    target.append(div);
	}
	break;
    case o.hasClass('icon-file'):
	if (target.find(".expando_text").length != 0) {
	    target.find(".expando_text").toggle();
	} else {
	    var hash = o.parent().find('a').attr('href').split("/").pop();
	    $.getJSON('/post/get/' + hash,
		      function(data) {
			  if (data.success) {
			      var div = $("<div class='expando_text'>").append($("<pre class='md'>").append(data.rendered_content));
			      target.append(div);
			  } else {
			      // FIXME
			  }
		      });
	}
	break;
    default:
	return false;
	break;
	//FIXME
    }
}
