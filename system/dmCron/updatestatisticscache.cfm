<cfsetting enablecfoutputonly="true" />
<!--- @@displayname: Google Analytics: Update statistics cache --->

<cfset qSettings = application.fapi.getContentObjects(typename="gaSetting") />
<cfset oStatistic = application.fapi.getContentType(typename="gaStatistic") />
<cfloop query="qSettings">
	<cfset oStatistic.updateStatistics(gaSettingID=qSettings.objectid) />
</cfloop>

<cfsetting enablecfoutputonly="false" />