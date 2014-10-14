<cfsetting enablecfoutputonly="yes">
<!--- @@displayname: Track event --->

<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />
<cfimport taglib="/farcry/core/tags/navajo" prefix="nj" />

<cfparam name="request.mode.ajax" default="false">
<!--- grab config --->

<cfif isdefined("application.fc.lib.ga")>
	<cfset stSetting = application.fc.lib.ga.getSettings() />

	<cfif NOT structIsEmpty(stSetting) and findnocase("/webtop",cgi.SCRIPT_NAME) eq 0 and  (not isdefined("url.view") or not reFindNoCase("(library|webtop|edit)",url.view)) and not GetPageContext().GetResponse().IsCommitted() and not request.mode.ajax >

		<cfset qCustomVars = application.fc.lib.ga.getCustomVars() />
		
		<!--- load/cache jquery --->
		<skin:loadJS id="jquery" />
		<skin:loadJS id="fcga" />
		
		<skin:htmlHead id="ga"><cfoutput><script type="text/javascript">
			$j.ga.setTracker('#stSetting.urchinCode#', { <cfif len(stSetting.types)>downloadClasses:['#listchangedelims(stSetting.types,"','")#']</cfif> });
			<cfloop query="qCustomVars">$j.ga.setCustomVar(#slot#,"#name#","#value#",#scope#);
			</cfloop>$j.ga.trackURL('#application.fc.lib.ga.getTrackableURL()#');
			
			(function() {
				var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
				<cfif structKeyExists(stSetting, "bDemographics") AND IsBoolean(stSetting.bDemographics) AND stSetting.bDemographics>
					ga.src = ('https:' == document.location.protocol ? 'https://' : 'http://') + 'stats.g.doubleclick.net/dc.js';
				<cfelse>
					ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
				</cfif>
				var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
			})();
		</script></cfoutput></skin:htmlHead>
	</cfif>
</cfif>

<cfsetting enablecfoutputonly="no">