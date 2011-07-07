<cfsetting enablecfoutputonly="true" />
<!--- @@displayname: Google Analytics --->

<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />

<cfset st = structnew() />
<cfset st.dimensions='ga:date' />
<cfset st.metrics='ga:pageviews,ga:uniquePageviews,ga:bounces,ga:entrances,ga:exits,ga:newVisits,ga:timeOnPage' />
<cfset st.startDate=dateadd("d",-7,now()) />
<cfset st.endDate=dateadd("d",-1,now()) />
<cfset st.maxResults=10 />
<cfset st.startIndex=1 />
<cfset st.filters='ga:pagePath%3D%3D'&urlencodedformat(application.fapi.getLink(objectid=stObj.objectid)) />

<cfset stLocal.o = application.fapi.getContentType(typename="gaSetting") />

<cfif stObj.typename neq "dmNavigation" and structkeyexists(application.stCOAPI[stObj.typename],"bUseInTree") and application.stCOAPI[stObj.typename].bUseInTree>
	<cfoutput>
		<ul id='errorMsg'>
			<li>The Google Analytics plugin tracks content in the tree against the navigation node it is attached to, so this area may not show any traffic.</li>
		</ul>
	</cfoutput>
</cfif>

<cfset stLocal.qSevenDay = stLocal.o.getGAData(argumentCollection=st).results />

<cfif stLocal.qSevenDay.recordcount>
	<cfoutput><h2>Seven Day Overview</h2></cfoutput>
	<cfchart format="png" style="#stLocal.o.getChartStyle('sevendayoverview')#" chartwidth="500" chartheight="400">
		<cfloop list="pageviews:Page views,bounces:Bounces,entrances:Entrances,exits:Exits,newVisits:New visits" index="stLocal.thischart">
			<cfchartseries type="line" query="stLocal.qSevenDay" itemcolumn="date" valuecolumn="#listfirst(stLocal.thischart,':')#" serieslabel="#listlast(stLocal.thischart,':')#" />
		</cfloop>
	</cfchart>

	<cfoutput><h2>Time On Page</h2></cfoutput>
	<cfchart format="png" style="#stLocal.o.getChartStyle('sevendayoverview')#" chartwidth="500" chartheight="300" showlegend="false">
		<cfloop list="timeOnPage:Time on page" index="stLocal.thischart">
			<cfchartseries type="line" query="stLocal.qSevenDay" itemcolumn="date" valuecolumn="#listfirst(stLocal.thischart,':')#" serieslabel="#listlast(stLocal.thischart,':')#" />
		</cfloop>
	</cfchart>
<cfelse>
	<cfoutput><p>There is no analytics information available at this time. Make sure the settings in the Google Analytics area of the webtop are up to date.</p></cfoutput>
</cfif>

<cfsetting enablecfoutputonly="false" />