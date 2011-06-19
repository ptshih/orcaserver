$(document).ready(function(){

// $("#submit2").click(function() {
//  var formData = $("#newcomment").serialize();
//  $.ajax({
//	type: "POST",
//	url: 
//	cache: false,
//	data: formData,
//	success: onSuccess
//  });

//  return false;
	
// });

$('#submit').click(function(e) {
	lineheight();
	e.preventDefault();
});

});// document.ready

$.fn.autoresize = function() {
	var minheight = $('#commentpost').height();
	var textwidth = $('#commentpost').css('width');
	
	var textdiv = $('<div></div>').css({
		position: 'absolute',
		top: -9999,
		left: -9999,
		width:  textwidth,
		'font-size': $('#commentpost').css('font-size'),
		'font-family': $('#commentpost').css('font-family'),
		'line-height': $('#commentpost').css('line-height'),
		resize: 'none',
		display: 'none'
	}).appendTo(document.body);
	
	var update = function(){
		var text = $('#commentpost').attr('value').replace(/</g, '&lt;')
												  .replace(/>/g, '&gt;')
												  .replace(/&/g, '&amp;');
		
		textdiv.html(text);
		$('#commentpost').css({height: Math.max(textdiv.height() + 30, minheight)});
	}
	$('#commentpost').change(update).keyup(update).keydown(update);
}


function onSuccess(data, status){
	resetTextFields();
	//notifications ex. checkmark icon on success
	data = $.trim(data);
	if(data == "SUCCESS") {
		//add checkmark .css div hidden mark remove? 
	} else {
		//add exclamation .css div mark add?
	}
}

function resetTextFields(){
	$('#commentpost').val('');
}