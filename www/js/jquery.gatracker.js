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
	$.ga = new (function(){
		var gatracker = "";
		var urlqueue = [];
		
		// until the tracker is set, trackURL just adds urls to the queue
		this.trackURL = function(url,customVars) {
			urlqueue.push({
				url: url,
				customVars: customVars || []
			});
		};
		
		// updates global scope with the Google tracker object, and processes any queued URLs
		this.setTracker = function(tracker) {
			var url = "";
			
			// update tracker
			gatracker = tracker;
			
			// update trackURL to actually report url
			this.trackURL = function(url,customVars) {
				customVars = customVars || [];
				for (var i = 0; i < customVars.length; i++) {
					gatracker._setCustomVar(i,customVars[i].name,customVars[i].value,customVars[i].scope);
				}
				
				gatracker._trackPageview(url);
			};
			
			// process queue
			while (trackData = urlqueue.shift()) {
				trackURL(trackData.url,trackData.customVars);
			}
		};
	})();
	
	// this jQuery function adds GA tracking to an element
	$.fn.track = function(params) {
		// default options
		params = jQuery.extend({
			event:		'click',
			external:	'/external/',
			mailto:		'/mailtos/',
			download:	'/downloads/',
			itunes:		'/itunes/',
			extensions: [
					'pdf','doc','xls','csv','jpg','gif', 'mp3',
					'swf','txt','ppt','zip','gz','dmg','xml'
			]
		}, params);
		
		// default url to track is href (obviously the default only works for links)
		params.urlfn = params.urlfn || function(el,ev,opts) { 
			var trackingURL = '';
			var u = el.href;
			var jQThis = $j(this);
			
			if (u.indexOf('://') == -1 && u.indexOf('mailto:') != 0){
				// no protocol or mailto - internal link - check extension
				var ext = u.split('.')[u.split('.').length - 1];			
				var exts = opts.extensions;
				
				for(i = 0; i < exts.length; i++){
					if(ext == exts[i]){
						trackingURL = opts.download + u;
						break;
					}
				}
			} else if (u.indexOf('mailto:') == 0){
				// mailto link - decorate
				trackingURL = opts.mailto + u.substring(7);
			} else if (u.indexOf('itpc://') == 0){
				trackingURL = opts.itunes + u.replace(/itpc\:\/\/[^\/]*[\/]?/,'');
			} else {
				// complete URL - check domain
				var regex = /([^:\/]+)*(?::\/\/)*([^:\/]+)(:[0-9]+)*\/?/i;
				var linkparts = regex.exec(u);
				var urlparts = regex.exec(location.href);
				if(linkparts[2] != urlparts[2]) trackingURL = opts.external + u.replace(/[^:\/]+\:\/\//,'');
			}
			
			return trackingURL;
		};
		
		// add the event to the passed in elements
		return this.unbind(params.event+'.track').bind(params.event+'.track',function(e){
			// track the url returned by the urlfn for this element and event
			var url = params.urlfn(this,e,params);
			if (url.length) $.ga.trackURL(url);
		});
	};
})(jQuery);
