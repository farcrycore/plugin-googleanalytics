<cfsetting enablecfoutputonly="true" />
<!--- @@displayname: Google Analytics --->

<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />

<cfif isdefined("url.getdata")>
	
	<cfparam name="url.period" /><!--- week | month | quarter | year --->
	<cfparam name="url.path" /><!--- exact | prefix --->
	<cfparam name="url.periodoffset" /><!--- 0 for this period, 1 for last period, etc. NOTE: in cases where periods don't have the same number of records (e.g. different numbers of days in months) they will be cut off to be the same as the current period --->
	
	<cfset application.fc.lib.ga.initializeRequest() />
	<cfset request.fc.ga.stObject = stObj />
	
	<cfset st = structnew() />
	<cfset st.metrics='ga:pageviews,ga:uniquePageviews,ga:bounces,ga:entrances,ga:exits,ga:newVisits,ga:timeOnPage' />
	<cfset st.startIndex=1 />
	
	<cfset stLocal.stResult = structnew() />
	
	<cfset stLocal.o = application.fapi.getContentType(typename="gaSetting") />
	
	<cfswitch expression="#url.path#">
		<cfcase value="exact">
			<cfset st.filters='ga:pagePath%3D%3D' & urlencodedformat(application.fc.lib.ga.getTrackableURL()) />
		</cfcase>
		
		<cfcase value="prefix">
			<cfset st.filters='ga:pagePath%3D~' & urlencodedformat("^" & replace(application.fc.lib.ga.getTrackableURL(),".","\.","ALL")) />
		</cfcase>
	</cfswitch>
	
	<cfswitch expression="#url.period#">
		<cfcase value="week"><!--- The week up to yesterday --->
			
			<!--- API query --->
			<cfset st.dimensions='ga:date,ga:hour' />
			<cfset st.endDate = dateadd("d",-1,createdatetime(year(now()),month(now()),day(now()),0,0,0)) />
			<cfset st.startDate = dateadd("d",-6,st.endDate) />
			<cfset st.maxResults = 24 * 7 />
			
			<cfset stLocal.qData = stLocal.o.getGAData(argumentCollection=st).results />
			
			<!--- Result metadata --->
			<cfset stLocal.stResult["linechart"] = structnew() />
			<cfset stLocal.stResult["linechart"]["xvalues"] = arrayrange(0,st.maxResults) />
			<cfset stLocal.stResult["dotchart"] = structnew() />
			<cfset stLocal.stResult["dotchart"]["xlabels"] = ["12am", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12pm", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11"] />
			<cfset stLocal.stResult["dotchart"]["ylabels"] = ["#dateformat(st.startDate,'ddd')#", "#dateformat(dateadd('d',1,st.startDate),'ddd')#", "#dateformat(dateadd('d',2,st.startDate),'ddd')#", "#dateformat(dateadd('d',3,st.startDate),'ddd')#", "#dateformat(dateadd('d',4,st.startDate),'ddd')#", "#dateformat(dateadd('d',5,st.startDate),'ddd')#", "#dateformat(dateadd('d',6,st.startDate),'ddd')#"] />
			<cfset stLocal.stResult["dotchart"]["xvalues"] = columntoarray(stLocal.qData,"hour") />
			<cfset stLocal.stResult["dotchart"]["yvalues"] = columntoarray(stLocal.qData,"dayofweek") />
			
			<cfif url.periodoffset>
				<cfset st.startDate = dateadd("d",-7 * url.periodOffset,st.startDate) />
				<cfset st.endDate = dateadd("d",-7 * url.periodOffset,st.endDate) />
				<cfset stLocal.qOffsetData = stLocal.o.getGAData(argumentCollection=st).results />
			</cfif>
			
		</cfcase>
		
		<cfcase value="month">
			<!--- This month --->
			<cfset st.dimensions='ga:date' />
			<cfset st.endDate = dateadd("d",-1,createdatetime(year(now()),month(now()),day(now()),0,0,0)) />
			<cfset st.startDate = dateadd("d",-29,st.endDate) />
			<cfset st.maxResults = (datediff("d",st.startDate,st.endDate) + 1) />
			
			<cfset stLocal.qData = stLocal.o.getGAData(argumentCollection=st).results />
			
			<!--- Result metadata --->
			<cfset stLocal.stResult["linechart"] = structnew() />
			<cfset stLocal.stResult["linechart"]["xvalues"] = arrayrange(0,st.maxResults) />
			<cfset stLocal.stResult["dotchart"] = structnew() />
			<cfset stLocal.stResult["dotchart"]["xlabels"] = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"] />
			<cfset stLocal.stResult["dotchart"]["ylabels"] = arrayrange(start=stLocal.qData.week[1],end=stLocal.qData.week[stLocal.qData.recordcount]+1,prefix="Week ") />
			<cfset stLocal.stResult["dotchart"]["xvalues"] = columntoarray(stLocal.qData,"dayofweek") />
			<cfset stLocal.stResult["dotchart"]["yvalues"] = columntoarray(stLocal.qData,"week") />
			<cfset stLocal.stResult["dotchart"]["width"] = 300 /><!--- Override default chart height --->
			
			<cfif url.periodoffset>
				<cfset st.endDate = dateadd("d",-1,dateadd("m",1,st.startDate)) />
				<cfset st.startDate = dateadd("d",-29,st.endDate) />
				<cfset stLocal.qOffsetData = stLocal.o.getGAData(argumentCollection=st).results />
			</cfif>
		</cfcase>
		
		<cfcase value="quarter">
			<!--- This quarter --->
			<cfset st.dimensions='ga:date' />
			<cfset st.endDate = dateadd("d",-1,createdatetime(year(now()),month(now()),day(now()),0,0,0)) />
			<cfset st.startDate = dateadd("d",-89,st.endDate) />
			<cfset st.maxResults = datediff("d",st.startDate,st.endDate) + 1 />
			
			<cfset stLocal.qData = stLocal.o.getGAData(argumentCollection=st).results />
			
			<!--- Result metadata --->
			<cfset stLocal.stResult["linechart"] = structnew() />
			<cfset stLocal.stResult["linechart"]["xvalues"] = arrayrange(0,st.maxResults) />
			<cfset stLocal.stResult["dotchart"] = structnew() />
			<cfset stLocal.stResult["dotchart"]["xlabels"] = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"] />
			<cfset stLocal.stResult["dotchart"]["ylabels"] = arrayrange(start=stLocal.qData.week[1],end=stLocal.qData.week[stLocal.qData.recordcount]+1,prefix="Week ") />
			<cfset stLocal.stResult["dotchart"]["xvalues"] = columntoarray(stLocal.qData,"dayofweek") />
			<cfset stLocal.stResult["dotchart"]["yvalues"] = columntoarray(stLocal.qData,"week") />
			<cfset stLocal.stResult["dotchart"]["width"] = 300 /><!--- Override default chart height --->
			<cfset stLocal.stResult["dotchart"]["height"] = 400 /><!--- Override default chart height --->
			
			<cfif url.periodoffset>
				<cfset st.endDate = dateadd("d",-1,st.startDate) />
				<cfset st.startDate = dateadd("d",-89,st.endDate) />
				<cfset stLocal.qOffsetData = stLocal.o.getGAData(argumentCollection=st).results />
			</cfif>
		</cfcase>
		
		<cfcase value="year">
			<!--- This year --->
			<cfset st.dimensions='ga:date' />
			<cfset st.endDate = dateadd("d",-1,createdatetime(year(now()),month(now()),day(now()),0,0,0)) />
			<cfset st.startDate = dateadd("d",-364,st.endDate) />
			<cfset st.maxResults = datediff("d",st.startDate,st.endDate) + 1 />
			
			<cfset stLocal.qData = stLocal.o.getGAData(argumentCollection=st).results />
			
			<!--- Result metadata --->
			<cfset stLocal.stResult["linechart"] = structnew() />
			<cfset stLocal.stResult["linechart"]["xvalues"] = arrayrange(0,st.maxResults) />
			<cfset stLocal.stResult["dotchart"] = structnew() />
			<cfset stLocal.stResult["dotchart"]["disabled"] = "There is no dot chart view for a year" />
			
			<cfif url.periodoffset>
				<cfset st.endDate = dateadd("d",-1,st.startDate) />
				<cfset st.startDate = dateadd("d",-364,st.endDate) />
				<cfset stLocal.qOffsetData = stLocal.o.getGAData(argumentCollection=st).results />
			</cfif>
		</cfcase>
	</cfswitch>
	
	
	
	<cfset stLocal.stResult["data"] = structnew() />
	<cfloop list="#stLocal.qData.columnlist#" index="stLocal.key">
		<cfset stLocal.stResult["data"][lcase(stLocal.key)] = columntoarray(stLocal.qData,stLocal.key) />
	</cfloop>
	
	<cfif url.periodoffset>
		<cfset stLocal.stResult["offsetdata"] = structnew() />
		<cfloop list="#stLocal.qOffsetData.columnlist#" index="stLocal.key">
			<cfset stLocal.stResult["offsetdata"][lcase(stLocal.key)] = columntoarray(stLocal.qOffsetData,stLocal.key) />
		</cfloop>
	</cfif>
	
	<cfcontent type="application/json" variable="#ToBinary( ToBase64( serializeJSON(stLocal.stResult) ) )#" reset="Yes">
	
<cfelse>
	
	<cfset stLocal.lineChartWidth = 390 />
	<cfset stLocal.lineChartHeight = 200 />
	<cfset stLocal.dotChartWidth = 680 />
	<cfset stLocal.dotChartHeight = 200 />
	
	<cfif stObj.typename neq "dmNavigation" and structkeyexists(application.stCOAPI[stObj.typename],"bUseInTree") and application.stCOAPI[stObj.typename].bUseInTree>
		<cfoutput>
			<ul id='errorMsg'>
				<li>The Google Analytics plugin tracks content in the tree against the navigation node it is attached to, so this area may not show any traffic.</li>
			</ul>
		</cfoutput>
	</cfif>
	
	<cfoutput>
		<script type="text/javascript" src="/googleanalytics/js/raphael-min.js"></script>
		<script type="text/javascript" src="/googleanalytics/js/g.raphael-min.js"></script>
		<script type="text/javascript" src="/googleanalytics/js/g.line-min.js"></script>
		<script type="text/javascript" src="/googleanalytics/js/g.dot-min.js"></script>
		<script type="text/javascript" src="/googleanalytics/js/googleanalytics.js"></script>
		<script type="text/javascript">GA.updateCharts("url","#application.url.webroot#/index.cfm?objectid=#stObj.objectid#&view=webtopOverviewTabGA&getdata=1");</script>
	</cfoutput>
	
	<cfoutput>
		<p>
			[ <a href="##" class="state-change" data-key="type" data-value="linechart" style="font-weight:bold;">line chart</a> | <a href="##" class="state-change" data-key="type" data-value="dotchart">dot chart</a> ]
			&nbsp;&nbsp;
			[ <a href="##" class="state-change" data-key="period" data-value="week" style="font-weight:bold;">last 7 days</a> | <a href="##" class="state-change" data-key="period" data-value="month">last 30 days</a> | <a href="##" class="state-change" data-key="period" data-value="quarter">last 90 days</a> | <a href="##" class="state-change" data-key="period" data-value="year">last 365 days</a> ]
			<cfif stObj.typename eq "dmNavigation">
				&nbsp;&nbsp;
				[ <a href="##" class="state-change" data-key="path" data-value="exact" style="font-weight:bold;">this item</a> | <a href="##" class="state-change" data-key="path" data-value="prefix">this section</a> ]
			</cfif>
		</p>
		<div id="charts"></div>
		
		<script type="text/html" id="linechart_template">
			<br><p>blue: recent period<br>green: the period before that</p>
			<table>
				<tr>
					<td><h2>Page Views</h2><div class="chart" data-metric="pageviews" style="width:#stLocal.lineChartWidth#px;height:#stLocal.lineChartHeight#px;"><img src="/googleanalytics/images/loading.gif" alt="loading..." style="margin-left:#(stLocal.lineChartWidth-32)/2#px;margin-top:#(stLocal.lineChartHeight-32)/2#px;"></div></td>
					<td><h2>Bounces</h2><div class="chart" data-metric="bounces" style="width:#stLocal.lineChartWidth#px;height:#stLocal.lineChartHeight#px;"><img src="/googleanalytics/images/loading.gif" alt="loading..." style="margin-left:#(stLocal.lineChartWidth-32)/2#px;margin-top:#(stLocal.lineChartHeight-32)/2#px;"></div></td>
				</tr>
				<tr>
					<td><h2>Entrances</h2><div class="chart" data-metric="entrances" style="width:#stLocal.lineChartWidth#px;height:#stLocal.lineChartHeight#px;"><img src="/googleanalytics/images/loading.gif" alt="loading..." style="margin-left:#(stLocal.lineChartWidth-32)/2#px;margin-top:#(stLocal.lineChartHeight-32)/2#px;"></div></td>
					<td><h2>Exits</h2><div class="chart" data-metric="exits" style="width:#stLocal.lineChartWidth#px;height:#stLocal.lineChartHeight#px;"><img src="/googleanalytics/images/loading.gif" alt="loading..." style="margin-left:#(stLocal.lineChartWidth-32)/2#px;margin-top:#(stLocal.lineChartHeight-32)/2#px;"></div></td>
				</tr>
				<tr>
					<td><h2>New visits</h2><div class="chart" data-metric="newVisits" style="width:#stLocal.lineChartWidth#px;height:#stLocal.lineChartHeight#px;"><img src="/googleanalytics/images/loading.gif" alt="loading..." style="margin-left:#(stLocal.lineChartWidth-32)/2#px;margin-top:#(stLocal.lineChartHeight-32)/2#px;"></div></td>
					<td><h2>Time on page</h2><div class="chart" data-metric="timeOnPage" style="width:#stLocal.lineChartWidth#px;height:#stLocal.lineChartHeight#px;"><img src="/googleanalytics/images/loading.gif" alt="loading..." style="margin-left:#(stLocal.lineChartWidth-32)/2#px;margin-top:#(stLocal.lineChartHeight-32)/2#px;"></div></td>
				</tr>
			</table>
		</script>
		
		<script type="text/html" id="dotchart_template">
			<table>
				<tr><td><h2>Page Views</h2></td><td><div class="chart" data-metric="pageviews" style="width:#stLocal.dotChartWidth#px;height:#stLocal.dotChartHeight#px;"><img src="/googleanalytics/images/loading.gif" alt="loading..." style="margin-left:#(stLocal.dotChartWidth-32)/2#px;margin-top:#(stLocal.dotChartHeight-32)/2#px;"></div></td></tr>
				<tr><td><h2>Bounces</h2></td><td><div class="chart" data-metric="bounces" style="width:#stLocal.dotChartWidth#px;height:#stLocal.dotChartHeight#px;"><img src="/googleanalytics/images/loading.gif" alt="loading..." style="margin-left:#(stLocal.dotChartWidth-32)/2#px;margin-top:#(stLocal.dotChartHeight-32)/2#px;"></div></td></tr>
				<tr><td><h2>Entrances</h2></td><td><div class="chart" data-metric="entrances" style="width:#stLocal.dotChartWidth#px;height:#stLocal.dotChartHeight#px;"><img src="/googleanalytics/images/loading.gif" alt="loading..." style="margin-left:#(stLocal.dotChartWidth-32)/2#px;margin-top:#(stLocal.dotChartHeight-32)/2#px;"></div></td></tr>
				<tr><td><h2>Exits</h2></td><td><div class="chart" data-metric="exits" style="width:#stLocal.dotChartWidth#px;height:#stLocal.dotChartHeight#px;"><img src="/googleanalytics/images/loading.gif" alt="loading..." style="margin-left:#(stLocal.dotChartWidth-32)/2#px;margin-top:#(stLocal.dotChartHeight-32)/2#px;"></div></td></tr>
				<tr><td><h2>New visits</h2></td><td><div class="chart" data-metric="newVisits" style="width:#stLocal.dotChartWidth#px;height:#stLocal.dotChartHeight#px;"><img src="/googleanalytics/images/loading.gif" alt="loading..." style="margin-left:#(stLocal.dotChartWidth-32)/2#px;margin-top:#(stLocal.dotChartHeight-32)/2#px;"></div></td></tr>
				<tr><td><h2>Time on page</h2></td><td><div class="chart" data-metric="timeOnPage" style="width:#stLocal.dotChartWidth#px;height:#stLocal.dotChartHeight#px;"><img src="/googleanalytics/images/loading.gif" alt="loading..." style="margin-left:#(stLocal.dotChartWidth-32)/2#px;margin-top:#(stLocal.dotChartHeight-32)/2#px;"></div></td></tr>
			</table>
		</script>
	</cfoutput>
	
</cfif>


<cffunction name="arrayrange" access="private" output="false" returntype="array" hint="Creates an array containing the specified range">
	<cfargument name="start" type="numeric" required="true" />
	<cfargument name="end" type="numeric" required="true" />
	<cfargument name="prefix" type="string" required="false" />
	
	<cfset var a = arraynew(1) />
	<cfset var i = 0 />
	
	<cfloop from="#arguments.start#" to="#arguments.end-1#" index="i">
		<cfif structkeyexists(arguments,"prefix")>
			<cfset arrayappend(a,arguments.prefix & i) />
		<cfelse>
			<cfset arrayappend(a,i) />
		</cfif>
	</cfloop>
	
	<cfreturn a />
</cffunction>

<cffunction name="arrayduplicate" access="private" output="false" returntype="array" hint="Extends the given array with copies of itself">
	<cfargument name="source" type="array" required="true" />
	<cfargument name="times" type="numeric" required="true" />
	
	<cfset var a = duplicate(arguments.source) />
	<cfset var i = 0 />
	
	<cfloop from="2" to="#arguments.times#" index="i">
		<cfset a.addAll(duplicate(arguments.source)) />
	</cfloop>
	
	<cfreturn a />
</cffunction>

<cffunction name="arraymid" access="private" output="false" returntype="array" hint="Standard slice functionality">
	<cfargument name="source" type="array" required="true" />
	<cfargument name="start" type="numeric" required="false" />
	<cfargument name="end" type="numeric" required="false" />
	
	<cfset var a = arraynew(1) />
	<cfset var i = 0 />
	
	<cfif arguments.start lt 0>
		<cfset arguments.start = arraylen(arguments.source) + arguments.start />
	</cfif>
	
	<cfif arguments.end lt 0>
		<cfset arguments.end = arraylen(arguments.source) + arguments.end />
	</cfif>
	
	<cfloop from="#arguments.start#" to="#min(arraylen(arguments.source),arguments.end)#" index="i">
		<cfset arrayappend(a,arguments.source[i]) />
	</cfloop>
	
	<cfreturn a />
</cffunction>

<cffunction name="columntoarray" access="private" output="false" returntype="array" hint="Returns a column as an array">
	<cfargument name="source" type="query" required="true" />
	<cfargument name="column" type="string" required="true" />
	
	<cfset var aResult = arraynew(1) />
	
	<cfloop query="arguments.source">
		<cfset arrayappend(aResult,arguments.source[arguments.column][arguments.source.currentrow]) />
	</cfloop>
	
	<cfreturn aResult />
</cffunction>

<cfsetting enablecfoutputonly="false" />