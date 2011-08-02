<cfsetting enablecfoutputonly="yes">
<!--- @@displayname: Track event --->

<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />
<cfimport taglib="/farcry/core/tags/navajo" prefix="nj" />

<!--- grab config --->
<cfset stSetting = application.fc.lib.ga.getSettings() />

<cfif NOT structIsEmpty(stSetting) and findnocase("/webtop",cgi.SCRIPT_NAME) eq 0>
	<cfset qCustomVars = application.fc.lib.ga.getCustomVars() />
	
	<!--- load/cache jquery --->
	<skin:loadJS id="jquery" />
	<skin:loadJS id="fcga" baseHREF="/farcry/plugins/googleanalytics/www/js/" lFiles="jquery.gatracker.js" />
	
	<skin:htmlHead id="ga"><cfoutput><script type="text/javascript">
		var _gaq = _gaq || [];
		_gaq.push(['_setAccount', '#stSetting.urchinCode#']);
		$j.ga.setTracker(_gaq,{ <cfif len(stSetting.types)>downloadClasses:['#listchangedelims(stSetting.types,"','")#']</cfif> });
		<cfloop query="qCustomVars">$j.ga.setCustomVar(#slot#,"#name#","#value#",#scope#);
		</cfloop>$j.ga.trackURL('#application.fc.lib.ga.getTrackableURL()#');
		
		(function() {
			var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
			ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
			var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
		})();
	</script></cfoutput></skin:htmlHead>
</cfif>

<cfsetting enablecfoutputonly="no">