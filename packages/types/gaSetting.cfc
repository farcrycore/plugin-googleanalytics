<cfcomponent displayname="Google Analytics configuration" hint="Configuration for Google Analytics" extends="farcry.core.packages.types.types" output="false">
	
	<cfproperty ftSeq="2" ftFieldset="Google Analytics Settings" name="bActive" type="boolean" default="1" hint="Urchin Code." ftLabel="Active" />
	<cfproperty ftSeq="3" ftFieldset="Google Analytics Settings" name="urchinCode" type="string" default="" hint="Urchin Code." ftLabel="Urchin Code" />
	<cfproperty ftSeq="4" ftFieldset="Google Analytics Settings" name="types" type="longchar" required="true" default="dmFile" ftLabel="Types" />
	<cfproperty ftSeq="5" ftFieldset="Google Analytics Settings" name="lDomains" type="longchar" default="" hint="Urchin Code." ftLabel="Domain(s)" ftHint="<strong>Optional:</strong> Leave empty to track all domains or define each domain on a new line." bLabel="true" />
	
	<cfproperty ftSeq="11" ftFieldset="Google Analytics API Access" name="email" type="string" ftType="email" ftLabel="Login Email Address" />
	<cfproperty ftSeq="12" ftFieldset="Google Analytics API Access" name="password" type="string" ftType="string" ftLabel="Password" ftRenderType="confirmpassword" />
	<cfproperty ftSeq="13" ftFieldset="Google Analytics API Access" name="appid" type="string" ftLabel="Application ID" ftHint="A string identifying your client application in the form companyName-applicationName-versionID" />
	<cfproperty ftSeq="14" ftFieldset="Google Analytics API Access" name="profileid" type="string" ftLabel="Profile" ftType="list" ftListData="getGAAccounts" />
	
	<cfproperty ftSeq="21" ftFieldset="Statistics Caching" name="cacheDays" type="integer" ftLabel="Days" ftHint="How many days back to consider" ftSectionHelp="Stastistics can be cached for use in 'Most Popular Article' type functionaliry." default="7" ftDefault="7" />
	
	
	<cffunction name="getSettings" access="public" output="false" returntype="struct">
		<cfargument name="host" required="true" type="string" default="#cgi.http_host#" />
		
		<cfset var qSites = queryNew("") />
		<cfset var stSetting = structNew() />
		<cfset var gaID = "" />

		<cftry>
			<cfquery datasource="#application.dsn#" name="qSites" cachedwithin="#createTimeSpan(0,0,1,0)#">
				SELECT objectID, lDomains
				FROM gaSetting
				WHERE
					lDomains LIKE <cfqueryparam cfsqltype="cf_sql_varchar" null="false" value="%#arguments.host#%" /> AND
					bActive = 1
			</cfquery>
			
			<cfif qSites.recordCount>
				<cfloop query="qSites">
					<cfloop list="#lDomains#" index="domain" delimiters="#chr(13)#">
						<cfif trim(domain) EQ cgi.http_host>
							<cfset gaID = qSites.objectID />
						</cfif>
					</cfloop>
				</cfloop>
				
				<cfif len(gaID)>
					<cfset stSetting = getData(gaID) />
				</cfif>

			<cfelse>
				<!--- check for blanket rule --->
				<cfquery datasource="#application.dsn#" name="qAll" cachedwithin="#createTimeSpan(0,0,1,0)#">
					SELECT objectID
					FROM gaSetting
					WHERE bActive = 1 AND lDomains IS NULL	
				</cfquery>
				<cfif qAll.recordCount>
					<cfset stSetting = getData(qAll.objectID) />						
				</cfif>
				
			</cfif>
			
			<cfcatch></cfcatch>
		</cftry>
	
		<cfreturn stSetting />
	</cffunction>
	
	<cffunction name="getGAAuthToken" access="public" output="false" returntype="string">
		<cfset var stSettings = getSettings() />
		<cfset var cfhttp = structnew() />
		<cfset var info = "" />
		
		<cfif not structkeyexists(stSettings,"email") or not len(stSettings.email) or not len(stSettings.password) or not len(stSettings.appid)>
			<cfreturn "" />
		<cfelseif isdefined("session.security.ga.auth") and session.security.ga.hash eq hash("#stSettings.email#-#stSettings.password#-#stSettings.appid#")>
			<cfreturn session.security.ga.auth />
		</cfif>
		
		<cfhttp url="https://www.google.com/accounts/ClientLogin" method="post">
			<cfhttpparam type="formfield" name="accountType" value="GOOGLE" />
			<cfhttpparam type="formfield" name="Email" value="#stSettings.email#" />
			<cfhttpparam type="formfield" name="Passwd" value="#stSettings.password#" />
			<cfhttpparam type="formfield" name="service" value="analytics" />
			<cfhttpparam type="formfield" name="source" value="#stSettings.appid#" />
		</cfhttp>
		
		<cfif cfhttp.statuscode eq "401 Unauthorized">
			<cfthrow message="Google API authorisation details not valid" />
		<cfelseif not cfhttp.statuscode eq "200 OK">
			<cfthrow message="Error accessing Google API: #cfhttp.statuscode#" />
		<cfelse>
			<cfset session.security.ga = structnew() />
			<cfset session.security.ga.hash = hash("#stSettings.email#-#stSettings.password#-#stSettings.appid#")>
			<cfloop list="#cfhttp.filecontent#" index="info" delimiters=" #chr(10)##chr(13)##chr(9)#">
				<cfset session.security.ga[listfirst(info,"=")] = listlast(info,"=") />
			</cfloop>
		</cfif>
		
		<cfreturn session.security.ga.auth />
	</cffunction>
	
	<cffunction name="getGAAccounts" access="public" output="false" returntype="query">
		<cfargument name="auth" type="string" required="false" hint="Google authorisation token" />
		
		<cfset var cfhttp = structnew() />
		<cfset var stResult = structnew() />
		<cfset var qAccounts = querynew("value,name") />
		<cfset var i = 0 />
		
		<cfparam name="arguments.auth" default="#getGAAuthToken()#" />
		
		<cfif len(arguments.auth)>
			<cfhttp url="https://www.google.com/analytics/feeds/accounts/default">
				<cfhttpparam type="header" name="Authorization" value="GoogleLogin auth=#arguments.auth#" />
			</cfhttp>
			
			<cfif not cfhttp.statuscode eq "200 OK">
				<cfthrow message="Error accessing Google API: #cfhttp.statuscode#" />
			<cfelse>
				<cfset stResult = xmlparse(cfhttp.filecontent) />
				<cfloop from="1" to="#arraylen(stResult.feed.entry)#" index="i">
					<cfset queryaddrow(qAccounts) />
					<cfset querysetcell(qAccounts,"value",listlast(stResult.feed.entry[i].id.xmlText,":")) />
					<cfset querysetcell(qAccounts,"name",stResult.feed.entry[i].title.xmlText) />
				</cfloop>
			</cfif>
		<cfelse>
			<cfset queryaddrow(qAccounts) />
			<cfset querysetcell(qAccounts,"value","") />
			<cfset querysetcell(qAccounts,"name","Enter account details first") />
		</cfif>
		
		<cfreturn qAccounts />
	</cffunction>
	
	<cffunction name="getGADataAll" access="public" output="false" returntype="struct">
		<!--- Same arguments as getGAData, without maxResults --->
		
		<cfset var stNewData = structnew() />
		
		<cfset arguments.startIndex = 1 />
		<cfset arguments.maxResults = 1000 />
		<cfset stNewData = getGAData(argumentCollection=arguments) />
		<cfset stData = stNewData />
		
		<cfloop condition="stNewData.results.recordcount and stNewData.startIndex + arguments.maxResults lte stNewData.totalResults">
			<cfset arguments.startIndex = arguments.startIndex + arguments.maxResults />
			<cfset stNewData = getGAData(argumentCollection=arguments) />
			<cfquery dbtype="query" name="stData.results">
				select	#stData.results.columnlist#
				from	stData.results
				
				UNION
				
				select	#stNewData.results.columnlist#
				from	stNewData.results
			</cfquery>
		</cfloop>
		
		<cfreturn stData />
	</cffunction>
	
	<cffunction name="getGAData" access="public" output="false" returntype="struct">
		<cfargument name="dimensions" type="string" required="false" />
		<cfargument name="metrics" type="string" required="true" />
		<cfargument name="sort" type="string" required="false" />
		<cfargument name="filters" type="string" required="false" />
		<cfargument name="segment" type="string" required="false" />
		<cfargument name="startDate" type="date" required="true" />
		<cfargument name="endDate" type="date" required="true" />
		<cfargument name="startIndex" type="string" required="false" />
		<cfargument name="maxResults" type="string" required="false" />
		<cfargument name="orderBy" type="string" required="false" />
		
		<cfset var stSettings = getSettings(cgi.http_host) />
		<cfset var cfhttp = structnew() />
		<cfset var stResult = structnew() />
		<cfset var url = "" />
		<cfset var auth = getGAAuthToken() />
		<cfset var i = 0 />
		<cfset var stReturn = structnew() />
		
		<cfset stReturn.results = querynew("empty") />
		<cfset stReturn.args = duplicate(arguments) />
		
		<cfif len(auth) and structkeyexists(stSettings,"profileid") and len(stSettings.profileid)>
			<cfset url = "https://www.google.com/analytics/feeds/data?ids=ga:#stSettings.profileid#" />
			
			<cfif structkeyexists(arguments,"dimensions")><cfset url = "#url#&dimensions=#arguments.dimensions#" /></cfif>
			<cfset url = "#url#&metrics=#arguments.metrics#" />
			<cfif structkeyexists(arguments,"sort")><cfset url = "#url#&sort=#arguments.sort#" /></cfif>
			<cfif structkeyexists(arguments,"filters")><cfset url = "#url#&filters=#arguments.filters#" /></cfif>
			<cfif structkeyexists(arguments,"segment")><cfset url = "#url#&segment=#arguments.segment#" /></cfif>
			<cfset url = "#url#&start-date=#dateformat(arguments.startDate,'yyyy-mm-dd')#" />
			<cfset url = "#url#&end-date=#dateformat(arguments.endDate,'yyyy-mm-dd')#" />
			<cfif structkeyexists(arguments,"startIndex")><cfset url = "#url#&start-index=#arguments.startIndex#" /></cfif>
			<cfif structkeyexists(arguments,"maxResults")><cfset url = "#url#&max-results=#arguments.maxResults#" /></cfif>
			
			<cfset url = "#url#&v=2&prettyprint=false" />
			
			<cfparam name="arguments.dimensions" default="" />
			
			<cfhttp url="#url#">
				<cfhttpparam type="header" name="Authorization" value="GoogleLogin auth=#auth#" />
			</cfhttp>

			<cfif not cfhttp.statuscode eq "200 OK">
				<cfthrow message="Error accessing Google API: #cfhttp.statuscode#" />
			<cfelse>
				<cfset stReturn.xml = xmlparse(cfhttp.filecontent) />
				<cfset stReturn.title = stReturn.xml.feed.title.xmlText />
				<cfset stReturn.id = stReturn.xml.feed.title.xmlText />
				<cfset stReturn.totalResults = stReturn.xml.feed.totalResults.xmlText />
				<cfset stReturn.startIndex = stReturn.xml.feed.startIndex.xmlText />
				
				<cfset stReturn.aggregates = structnew() />
				<cfloop from="1" to="#arraylen(stReturn.xml.feed.aggregates.metric)#" index="i">
					<cfset stReturn.aggregates[listlast(stReturn.xml.feed.aggregates.metric[i].xmlAttributes.name,":")] = stReturn.xml.feed.aggregates.metric[i].xmlAttributes.value />
				</cfloop>
				
				<cfif structkeyexists(stReturn.xml.feed,"entry")>
					<cfset stReturn.results = createResultQuery(arguments.dimensions,arguments.metrics,stReturn.xml.feed.entry) />
				<cfelse>
					<cfset stReturn.results = createResultQuery(arguments.dimensions,arguments.metrics) />
				</cfif>
			</cfif>
		</cfif>
		
		<cfreturn stReturn />
	</cffunction>
	
	<cffunction name="createResultQuery" access="public" output="false" returntype="query" hint="Creates a result query for the specified dimensions and metrics">
		<cfargument name="dimensions" type="string" required="true" />
		<cfargument name="metrics" type="string" required="true" />
		<cfargument name="results" type="any" required="false" />
		
		<cfset var columns = listappend(replace(arguments.dimensions,"ga:","","all"),replace(arguments.metrics,"ga:","","all")) />
		<cfset var columntypes = "" />
		<cfset var thiscolumn = "" />
		<cfset var qResult = "" />
		<cfset var i = 0 />
		<cfset var j = 0 />
		
		<cfloop list="#columns#" index="thiscolumn">
			<cfswitch expression="#thiscolumn#">
				<cfcase value="date">
					<cfset columntypes = listappend(columntypes,"date") />
				</cfcase>
				<cfcase value="pageviews,uniquePageviews,bounces,entrances,exits,newVisits,timeOnPage,hour" delimiters=",">
					<cfset columntypes = listappend(columntypes,"Integer") />
				</cfcase>
				<cfdefaultcase>
					<cfset columntypes = listappend(columntypes,"varchar") />
				</cfdefaultcase>
			</cfswitch>
		</cfloop>
		
		<cfset qResult = querynew(columns,columntypes) />
		
		<cfif structkeyexists(arguments,"results")>
			<cfloop from="1" to="#arraylen(arguments.results)#" index="i">
				<cfset queryaddrow(qResult) />
				<cfloop from="1" to="#arraylen(arguments.results[i]['dxp:dimension'])#" index="j">
					<cfset setResultValue(qResult,arguments.results[i]['dxp:dimension'][j].xmlAttributes.name,arguments.results[i]['dxp:dimension'][j].xmlAttributes.value) />
				</cfloop>
				<cfloop from="1" to="#arraylen(arguments.results[i]['dxp:metric'])#" index="j">
					<cfset setResultValue(qResult,arguments.results[i]['dxp:metric'][j].xmlAttributes.name,arguments.results[i]['dxp:metric'][j].xmlAttributes.value) />
				</cfloop>
			</cfloop>
		</cfif>
		
		<cfreturn qResult />
	</cffunction>
	
	<cffunction name="setResultValue" access="public" output="false" returntype="void" hint="Sets a value in a result query, according to the relevant type">
		<cfargument name="query" type="query" required="true" hint="The result query" />
		<cfargument name="key" type="string" required="true" hint="The value name" />
		<cfargument name="value" type="string" required="true" hint="The value" />
		
		<cfset arguments.key = listlast(arguments.key,":") />
		
		<cfswitch expression="#arguments.key#">
			<cfcase value="date">
				<cfset querysetcell(arguments.query,arguments.key,createdate(left(arguments.value,"4"),mid(arguments.value,5,2),right(arguments.value,2))) />
			</cfcase>
			<cfdefaultcase>
				<cfset querysetcell(arguments.query,arguments.key,arguments.value) />
			</cfdefaultcase>
		</cfswitch>
	</cffunction>
	
	<cffunction name="getChartStyle" access="public" output="false" returntype="string" hint="The path of the seven-day chart style xml">
		<cfargument name="chart" type="string" required="true" hint="The name of the chart being displayed" />
		
		<cfset var xml = "" />
		
		<cffile action="read" file="#expandpath('/farcry/plugins/googleanalytics/www/sevenday.xml')#" variable="xml" />
		
		<cfreturn xml />
	</cffunction>
	
</cfcomponent>