jQuery(document).ready(function($){

	$(".menu-toggle").on("click", function(e) {
		if($('nav.main-navigation').hasClass('toggled') == true) {
			$('nav.main-navigation').removeClass('toggled');
		}else{
			$('nav.main-navigation').addClass('toggled');
		}
	});

});