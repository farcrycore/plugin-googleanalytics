<cfsetting enablecfoutputonly="true" />
<!--- @@cacheStatus: 1 --->
<!--- @@cacheTypeWatch: gaStatistic --->

<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />

<cfset stLocal.qItems = getObjects(stObj) />

<cfoutput>
	<h2>#stObj.title#</h2>
	<cfif len(stObj.intro)><p>#stObj.intro#</p></cfif>
	<ul>
</cfoutput>

<cfloop query="stLocal.qItems">
	<cfset stLocal.st = application.fapi.getContentObject(typename=stLocal.qItems.typename,objectid=stLocal.qItems.objectid) />
	<cfif structkeyexists(stLocal.st,"title")>
		<cfset stLocal.title = stLocal.st.title />
	<cfelse>
		<cfset stLocal.title = stLocal.st.label />
	</cfif>
	<cfif structkeyexists(application.stCOAPI[stLocal.qItems.typename],"displayname")>
		<cfset stLocal.contenttype = application.stCOAPI[stLocal.qItems.typename].displayname />
	<cfelse>
		<cfset stLocal.contenttype = stLocal.qItems.typename />
	</cfif>
	<cfoutput><li><skin:buildLink objectid="#stLocal.qItems.objectid#">#stLocal.contenttype#: #stLocal.title#</skin:buildLink></li></cfoutput>
</cfloop>

<cfoutput>
	</ul>
</cfoutput>

<cfsetting enablecfoutputonly="false" />