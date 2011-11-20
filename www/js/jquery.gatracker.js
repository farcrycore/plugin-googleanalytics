// USAGE:
// 
// At some point the tracker needs to be specified:
//	$.ga.setTracker(tracker);
// If there are any urls already queued they are processed at this point
//
// Tracking can be added to elements with track (all parameters are optional):
//  $().track({ event:"", urlfn:function(){}, opts:{} });
// event: any valid jQuery event, "click" by default
// urlfn: a function that takes the element, the event object, and the opts object
//		  and returns a trackable url, does processing for external/mail/files by 
//		  default
// opts: parameters to pass into the urlfn, specifies the prefixes for external/mail/
//		 file links and the file links to track
//
// Tracking of an arbitrary url can be done at any point with:
//	$.ga.track(url);
// If the tracker hasn't been set, the url gets queued


(function($){
	var defaultParams = {
		event:		'click',
		external:	'/external/',
		mailto:		'/mailtos/',
		download:	'/downloads/',
		itunes:		'/itunes/',
		extensions: [
				'pdf','doc','xls','csv','jpg','gif', 'mp3',
				'swf','txt','ppt','zip','gz','dmg','xml'
		],
		downloadClasses : [],
		// default url to track is href (obviously the default only works for links)
		urlfn : function urlFN(el,ev,opts) {
			var u = el.href || el.action;
			var jQThis = $(this);
			
			if (u.indexOf('://') == -1 && u.indexOf('mailto:') != 0){ // no protocol or mailto - internal link
				
				// check for farcry downloads
				if (u.indexOf("/download.cfm?")>-1){
					var title = jQThis.attr("title") || el.innerHTML;
					return opts.download + title.replace(/<[^>]+>/g,'-').replace(/[^\w]+/g,'-');
				}
				
				// check extension
				var ext = u.split('.')[u.split('.').length - 1];			
				var exts = opts.extensions;
				
				for(i = 0; i < exts.length; i++){
					if(ext == exts[i]) return opts.download + u;
				}
				
				// check for download classes
				for (var i=0;i<opts.downloadClasses;i++){
					if(jQThis.hasClass(opts.downloadClasses[i])){
						var title = jQThis.attr("title") || el.innerHTML;
						return opts.download + title.replace(/<[^>]+>/g,'-').replace(/[^\w]+/g,'-');
					}
				}	
			} else if (u.indexOf('mailto:') == 0){
				// mailto link - decorate
				return opts.mailto + u.substring(7);
			} else if (u.indexOf('itpc://') == 0){
				return opts.itunes + u.replace(/itpc\:\/\/[^\/]*[\/]?/,'');
			} else {
				// complete URL - check domain
				var regex = /([^:\/]+)*(?::\/\/)*([^:\/]+)(:[0-9]+)*\/?/i;
				var linkparts = regex.exec(u);
				var urlparts = regex.exec(location.href);
				if(linkparts[2] != urlparts[2]) return opts.external + u.replace(/[^:\/]+\:\/\//,'');
			}
			
			return "";
		}
	};
	
	$.ga = new (function(){
		var _gaq = [];
		
		// until the tracker is set, trackURL just adds urls to the queue
		this.trackURL = function trackURL(url) {
			_gaq.push(['_trackPageview', url]);
		};
		
		// custom variables
		this.encodedLength = function(input) { return encodeURIComponent(input).length; };
		this.setCustomVar = function setCustomVar(slot,name,value,scope){
			if (this.encodedLength(name) + this.encodedLength(value) > 64) {
				var nameLen = 64 - this.encodedLength(name);
				var trimmedVal = encodeURIComponent(value).substr(0,nameLen).replace(/(%\w{2})?%\w?$/,"");
				value = decodeURIComponent(trimmedVal);
			}
			_gaq.push(['_setCustomVar',slot,name,value,scope]);
		};
		
		// updates global scope with the Google tracker object, and sets up default tracking
		this.setTracker = function setTracker(tracker,params) {
			for (var i=_gaq.length-1;i>=0;i--)
				tracker.unshift(_gaq[i]);
			_gaq = tracker;
			
			$(function setupJqueryGA(){
				// default options
				params = jQuery.extend(defaultParams, params);
				
				// setup tracking
				$j("a").track(); // track external links, files, email addresses
				$j("form").track({ event:"submit" }); // track external links
			});
		};
	})();
	
	// this jQuery function adds GA tracking to an element
	$.fn.track = function(params) {
		// default options
		params = jQuery.extend(defaultParams, params);
		
		// add the event to the passed in elements
		return this.unbind(params.event+'.track').bind(params.event+'.track',function(e){
			// track the url returned by the urlfn for this element and event
			var url = params.urlfn(this,e,params);
			if (url.length) $.ga.trackURL(url);
		});
	};
})(jQuery);