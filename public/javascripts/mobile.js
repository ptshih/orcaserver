$(document).ready(function(){

});// end document.ready

function sendmessage(e) {
	alert('function called');
  var formData = $("#newcomment").serialize();

  if (formData.length > 0) {
    $.ajax({
		type: "POST",
		url: "http://localhost:3000/v1/pods/1/messages/create?",
		cache: false,
		data: formData,
		success: onSuccess
  	});
  }
	e.preventDefault();
}

function podbtn() {
	alert('pod button clicked');
	resetTextFields();
}

$.fn.autoresize = function() {
	var minheight = $('#message').height();
	var textwidth = $('#message').css('width');
	
	var textdiv = $('<div></div>').css({
		position: 'absolute',
		top: -9999,
		left: -9999,
		width:  textwidth,
		'font-size': $('#message').css('font-size'),
		'font-family': $('#message').css('font-family'),
		'line-height': $('#message').css('line-height'),
		resize: 'none',
		display: 'none'
	}).appendTo(document.body);
	
	var update = function(){
		var text = $('#message').attr('value').replace(/</g, '&lt;')
												  .replace(/>/g, '&gt;')
												  .replace(/&/g, '&amp;');
		
		textdiv.html(text);
		$('#message').css({height: Math.max(textdiv.height() + 30, minheight)});
	}
	$('#message').change(update).keyup(update).keydown(update);
}


function onSuccess(data){
	resetTextFields();
	alert('Success!!!!!!!');
	//notifications ex. checkmark icon on success
	data = $.trim(data);
	// if(data == "SUCCESS") {
	// 	//add checkmark .css div hidden mark remove? 
	// } else {
	// 	//add exclamation .css div mark add?
	// }
}

function resetTextFields(){
	$('#message').val('');
}