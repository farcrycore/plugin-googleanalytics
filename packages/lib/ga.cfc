<cfcomponent displayname="Google Analytics" hint="Google Analytics access" output="false">

	<cfset this.cvScopes = structnew() />
	<cfset this.cvScopes.visitor = 1 />
	<cfset this.cvScopes.session = 2 />
	<cfset this.cvScopes.page = 3 />
	
	<cffunction name="initializeRequest" access="public" output="false" returntype="void" hint="Sets up the request to collect tracking information">
		
		<cfparam name="request.fc" default="#structnew()#" />
		<cfset request.fc.ga = structnew() />
		<cfset request.fc.ga.aCustomVars = arraynew(1) />
		<cfset arrayset(request.fc.ga.aCustomVars,1,5,"") />
	</cffunction>
	
	<cffunction name="setCustomVar" access="public" output="false" returntype="void" hint="Flags a custom variable for google analytics tracking">
		<cfargument name="slot" type="numeric" required="false" hint="Defaults to first empty slot" />
		<cfargument name="name" type="string" required="true" />
		<cfargument name="value" type="string" required="true" />
		<cfargument name="scope" type="string" required="true" />
		
		<cfset var i = 0 />
		<cfset var stCV = structnew() />
		
		<!--- Set default slot, error check slot --->
		<cfif not structkeyexists(arguments,"slot")>
			<cfloop from="1" to="#arraylen(request.fc.ga.aCustomvars)#" index="i">
				<cfif issimplevalue(request.fc.ga.aCustomVars[i])>
					<cfset arguments.slot = i />
					<cfbreak />
				</cfif>
			</cfloop>
		</cfif>
		<cfif not structkeyexists(arguments,"slot") or not isnumeric(arguments.slot) or arguments.slot lt 1 or arguments.slot gt 5>
			<cfthrow message="Either there are no spare custom variable slots, or an invalid slot number was specified" />
		</cfif>
		
		<cfset stCV = structnew() />
		<cfif isnumeric(arguments.scope)>
			<cfset stCV.scope = arguments.scope />
		<cfelse>
			<cfset stCV.scope = this.cvScopes[arguments.scope] />
		</cfif>
		<cfset stCV.name = arguments.name />
		<cfset stCV.value = arguments.value />
		<cfset request.fc.ga.aCustomVars[arguments.slot] = stCV />
	</cffunction>
	
	<cffunction name="getCustomVars" access="public" output="false" returntype="any" hint="">
		<cfargument name="format" type="string" required="false" default="cfml" hint="json | cfml" />
		
		<cfset var q = querynew("slot,name,value,scope","integer,varchar,varchar,integer") />
		<cfset var i = 0 />

		<cfif structKeyExists(request, "stObj") and not isstruct(request.fc.ga.aCustomVars[4]) and not isstruct(request.fc.ga.aCustomVars[5])>
			<cfset setCustomVar(4, "typename", request.stObj.typename, "page") />
			<cfset setCustomVar(5, "objectid", request.stObj.objectid, "page") />
		</cfif>

		<cfloop from="1" to="#arraylen(request.fc.ga.aCustomVars)#" index="i">
			<cfif isstruct(request.fc.ga.aCustomVars[i])>
				<cfset queryaddrow(q) />
				<cfset querysetcell(q,"slot", i) />
				<cfset querysetcell(q,"name",request.fc.ga.aCustomVars[i].name) />
				<cfset querysetcell(q,"value",request.fc.ga.aCustomVars[i].value) />
				<cfset querysetcell(q,"scope",request.fc.ga.aCustomVars[i].scope) />
			</cfif>
		</cfloop>
		
		<cfreturn q />
	</cffunction>
	
	<cffunction name="setSettingsHost" access="public" output="false" returntype="void" hint="Used by the plugin to determine which tracking settings to use for this request">
		<cfargument name="host" type="string" required="true" />
		
		<cfset request.fc.ga.host = arguments.host />
	</cffunction>

	<cffunction name="getSettingsHost" access="public" output="false" returntype="string" hint="If no host has been set, returns cgi.http_host">
		
		<cfif isdefined("request.fc.ga.host")>
			<cfreturn request.fc.ga.host />
		<cfelse>
			<cfreturn cgi.http_host />
		</cfif>
	</cffunction>
	
	<cffunction name="setTrackableURL" access="public" output="false" returntype="void" hint="Use to force the tracked URL to be something specific">
		<cfargument name="stObject" type="struct" required="false" hint="The property struct for this page. Can be substituted for objectid for slightly better performance." />
		<cfargument name="url" type="string" required="false" hint="Track an arbitrary URL" />
		
		<cfif structkeyexists(arguments,"url")>
			<cfset request.fc.ga.url = arguments.url />
		<cfelseif structkeyexists(arguments,"stObject")>
			<!--- We have the struct, but not the typename --->
			<cfset request.fc.ga.stObject = arguments.stObject />
			<cfif not structkeyexists(request.fc.ga.stObject,"typename")>
				<cfset request.fc.ga.stObject.typename = application.coapi.findType(request.fc.ga.stObject.objectid) />
			</cfif>
		</cfif>
	</cffunction>
	
	<cffunction name="getTrackableURL" access="public" output="false" returntype="string" hint="If no URL has been specifically set, attempts to generate an appropriate URL for the current object or type webskin">
		<cfargument name="objectid" type="uuid" required="false" />
		
		<cfset var trackableURL = "" />
		<cfset var stNav = structnew() />
		<cfset var stSettings = application.fapi.getContentType("gaSetting").getSettings() />
		<cfset var urlVar = "" />
		
		<cfimport taglib="/farcry/core/tags/navajo" prefix="nj" />
		
		<cfif not structkeyexists(request.fc.ga,"stObject") and isDefined("request.stObj.objectID") and isValid("uuid",request.stObj.objectID)>
			<cfset request.fc.ga.stObject = request.stObj />
		</cfif>
		
		<cfif structkeyexists(arguments,"objectid")>
			<!--- look up the object's parent navigaion node --->
			<nj:getNavigation objectId="#arguments.objectId#" r_stobject="stNav" />
			
			<!--- if the object is in the tree this will give us the node --->
			<cfif isStruct(stNav) and structKeyExists(stNav, "objectid") AND len(stNav.objectid)>
				<cfset trackableURL = application.fapi.getLink(objectid=stNav.objectID) />
			<cfelse>
				<cfset trackableURL = application.fapi.getLink(objectid=arguments.objectid) />
			</cfif>
		<cfelseif structkeyexists(request.fc.ga,"url")>
			<cfset trackableURL = request.fc.ga.url />
		<cfelseif not structkeyexists(request.fc.ga,"stObject")>
			<cfset trackableURL = application.fapi.fixURL() />
		<cfelseif request.fc.ga.stObject.typename eq "farCOAPI">
			<cfset trackableURL = application.fapi.fixURL() />
			
			<cfif find("/index.cfm?",trackableURL)>
				<cfset trackableURL = "/#application.stCOAPI[request.fc.ga.stObject.name].fuAlias#" />
				<cfif len(url.view) and url.view neq "displayPageStandard">
					<cfset trackableURL = "#trackableURL#/#application.stCOAPI[request.fc.ga.stObject.name].stWebskins[url.view].fuAlias#" />
				</cfif>
				<cfif len(url.bodyview) and url.bodyview neq "displayTypeBody">
					<cfset trackableURL = "#trackableURL#/#application.stCOAPI[request.fc.ga.stObject.name].stWebskins[url.bodyview].fuAlias#" />
				</cfif>
			</cfif>
		<cfelse>
			<cfif len(request.fc.ga.stObject.objectid) AND structKeyExists(application.stCoapi["#request.fc.ga.stObject.typename#"], "bUseInTree") AND application.stCoapi["#request.fc.ga.stObject.typename#"].bUseInTree>
				<!--- look up the object's parent navigaion node --->
				<nj:getNavigation objectId="#request.fc.ga.stObject.objectId#" r_stobject="stNav" />
				
				<!--- if the object is in the tree this will give us the node --->
				<cfif isStruct(stNav) and structKeyExists(stNav, "objectid") AND len(stNav.objectid)>
					<cfset trackableURL = application.fapi.getLink(objectid=stNav.objectID) />
				<cfelse>
					<cfset trackableURL = application.fapi.getLink(objectid=request.fc.ga.stObject.objectid) />
				</cfif>
            <cfelseif isValid("uuid", request.fc.ga.stObject.objectid)>
                <cfset trackableURL = application.fapi.getLink(objectid=request.fc.ga.stObject.objectid) />
            <cfelse>
                <cfset trackableURL = application.fapi.fixURL() />
            </cfif>
			
			<cfif find("/index.cfm?",trackableURL)>
				<cfset trackableURL = "/#application.stCOAPI[request.fc.ga.stObject.typename].fuAlias#/#rereplace(rereplace(request.fc.ga.stObject.label,'\s+','-','ALL'),'[^\w\-]','','ALL')#" />
			</cfif>
			<cfif len(url.view) and url.view neq "displayPageStandard" and (not structkeyexists(request.fc.ga.stObject,"displaymethod") or request.fc.ga.stObject.displaymethod neq url.view)>
				<cfset trackableURL = "#trackableURL#/#application.stCOAPI[request.fc.ga.stObject.typename].stWebskins[url.view].fuAlias#" />
			</cfif>
			<cfif len(url.bodyview) and url.bodyview neq "displayBody">
				<cfset trackableURL = "#trackableURL#/#application.stCOAPI[request.fc.ga.stObject.typename].stWebskins[url.bodyview].fuAlias#" />
			</cfif>
		</cfif>
		
		<cfif structkeyexists(stSettings,"urlWhiteList") and not structkeyexists(arguments,"objectid")>
			<cfloop list="#stSettings.urlWhiteList#" index="urlVar">
				<cfif structkeyexists(url,urlVar) and not refindnocase("[&?]#urlVar#=",trackableURL)>
					<cfif find("?",trackableURL)>
						<cfset trackableURL = "#trackableURL#&#urlVar#=#url[urlVar]#" />
					<cfelse>
						<cfset trackableURL = "#trackableURL#?#urlVar#=#url[urlVar]#" />
					</cfif>
				</cfif>
			</cfloop>
		</cfif>
		
		<cfreturn trackableURL />
	</cffunction>
	
	<cffunction name="getAccounts" access="public" output="false" returntype="query">
		<cfargument name="accessConfig" type="struct" required="true" />
		
		<cfset var stResult = structnew() />
		<cfset var qAccounts = querynew("id,name") />
		<cfset var i = 0 />
		
		<cfset stResult = application.fc.lib.google.makeRequest(
			accessConfig = arguments.accessConfig,
			resource = "/analytics/v3/management/accounts"
		) />

		<cfset qAccounts = application.fc.lib.google.itemsToQuery(items=stResult.items, order="[name] asc") />
		
		<cfreturn qAccounts />
	</cffunction>
	
	<cffunction name="getWebProperties" access="public" output="false" returntype="query">
		<cfargument name="accountID" type="string" required="true" />
		<cfargument name="accessConfig" type="struct" required="true" />
		
		<cfset var stResult = structnew() />
		<cfset var qWebProperties = querynew("id,name") />
		<cfset var i = 0 />
		
		<cfset stResult = application.fc.lib.google.makeRequest(
			accessConfig = arguments.accessConfig,
			resource = "/analytics/v3/management/accounts/#arguments.accountID#/webproperties"
		) />
		
		<cfset qWebProperties = application.fc.lib.google.itemsToQuery(items=stResult.items, order="[name] asc") />
		
		<cfreturn qWebProperties />
	</cffunction>
	
	<cffunction name="getProfiles" access="public" output="false" returntype="query">
		<cfargument name="accountID" type="string" required="true" />
		<cfargument name="webPropertyID" type="string" required="true" />
		<cfargument name="accessConfig" type="struct" required="true" />
		
		<cfset var stResult = structnew() />
		<cfset var qProfiles = querynew("id,name") />
		<cfset var i = 0 />
		
		<cfset stResult = application.fc.lib.google.makeRequest(
			accessConfig = arguments.accessConfig,
			resource = "/analytics/v3/management/accounts/#arguments.accountID#/webproperties/#arguments.webPropertyID#/profiles"
		) />
		
		<cfset qProfiles = application.fc.lib.google.itemsToQuery(items=stResult.items, order="[name] asc") />
		
		<cfreturn qProfiles />
	</cffunction>
	
	<cffunction name="createResultQuery" access="public" output="false" returntype="query" hint="Creates a result query for the specified dimensions and metrics">
		<cfargument name="columns" type="array" required="false" />
		<cfargument name="rows" type="array" required="false" />
		
		<cfset var columnnames = "" />
		<cfset var columntypes = "" />
		<cfset var thiscolumn = "" />
		<cfset var qResult = "" />
		<cfset var i = 0 />
		<cfset var j = 0 />
		<cfset var dateColumns = "" />
		<cfset var thisValue = "" />
		
		<cfloop from="1" to="#arraylen(arguments.columns)#" index="thiscolumn">
			<cfset columnnames = listappend(columnnames,listlast(arguments.columns[thiscolumn].name,":")) />
			
			<cfswitch expression="#arguments.columns[thiscolumn].dataType#">
				<cfcase value="STRING">
					<cfset columntypes = listappend(columntypes,"varchar") />
				</cfcase>
				<cfcase value="INTEGER">
					<cfset columntypes = listappend(columntypes,"integer") />
				</cfcase>
				<cfcase value="FLOAT,CURRENCY,PERCENT" delimiters=",">
					<cfset columntypes = listappend(columntypes,"decimal") />
				</cfcase>
				<cfcase value="DATE,TIME" delimiters=",">
					<cfset columntypes = listappend(columntypes,"date") />
					<cfset dateColumns = listappend(dateColumns,arguments.columns[thiscolumn].name) />
				</cfcase>
				<cfdefaultcase>
					<cfset columntypes = listappend(columntypes,"varchar") />
				</cfdefaultcase>
			</cfswitch>
		</cfloop>
		
		<cfset qResult = querynew(columnnames,columntypes) />
		
		<cfif structkeyexists(arguments,"rows")>
			<cfloop from="1" to="#arraylen(arguments.rows)#" index="i">
				<cfset queryaddrow(qResult) />
				
				<cfloop from="1" to="#arraylen(arguments.rows[i])#" index="j">
					<cfset thisColumn = listlast(arguments.columns[j].name,":") />
					<cfset thisValue = arguments.rows[i][j] />
					
					<cfif listfindnocase(dateColumns,j)>
						<cfset querysetcell(qResult,thisColumn,createdate(left(thisValue,"4"),mid(thisValue,5,2),right(thisValue,2))) />
					<cfelse>
						<cfset querysetcell(qResult,thisColumn,thisValue) />
					</cfif>
				</cfloop>
			</cfloop>
		</cfif>
		
		<cfreturn qResult />
	</cffunction>
	
	<cffunction name="getData" access="public" output="false" returntype="struct">
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
		
		<cfargument name="profileID" type="string" required="true" />
		<cfargument name="accessConfig" type="struct" required="true" />
		
		
		<cfset var stResult = structnew() />
		<cfset var stQuery = {} />
		<cfset var i = 0 />
		<cfset var stReturn = structnew() />
		
		<cfset stReturn.results = querynew("empty") />
		<cfset stReturn.args = duplicate(arguments) />
		
		<cfset stQuery["ids"] = "ga:#arguments.profileID#" />
		<cfif structkeyexists(arguments,"dimensions")>
			<cfset stQuery["dimensions"] = arguments.dimensions />
		</cfif>
		<cfset stQuery["metrics"] = arguments.metrics />
		<cfif structkeyexists(arguments,"sort")>
			<cfset stQuery["sort"] = arguments.sort />
		</cfif>
		<cfif structkeyexists(arguments,"filters")>
			<cfset stQuery["filters"] = arguments.filters />
		</cfif>
		<cfif structkeyexists(arguments,"segment")>
			<cfset stQuery["segment"] = arguments.segment />
		</cfif>
		<cfset stQuery["start-date"] = dateformat(arguments.startDate,'yyyy-mm-dd') />
		<cfset stQuery["end-date"] = dateformat(arguments.endDate,'yyyy-mm-dd') />
		<cfif structkeyexists(arguments,"startIndex")>
			<cfset stQuery["start-index"] = arguments.startIndex />
		</cfif>
		<cfif structkeyexists(arguments,"maxResults")>
			<cfset stQuery["max-results"] = arguments.maxResults />
		</cfif>
		<cfset stQuery["prettyprint"] = "false" />
		
		<cfparam name="arguments.dimensions" default="" />
		
		<cfset stReturn.data = application.fc.lib.google.makeRequest(
			accessConfig = arguments.accessConfig,
			resource = "/analytics/v3/data/ga",
			stQuery = stQuery
		) />
		
		<cfset stReturn.id = stReturn.data.id />
		<cfset stReturn.totalResults = stReturn.data.totalResults />
		<cfset stReturn.startIndex = stReturn.data.query["start-index"] />
		
		<cfset stReturn.aggregates = structnew() />
		<cfloop collection="#stReturn.data.totalsForAllResults#" item="i">
			<cfset stReturn.aggregates[i] = stReturn.data.totalsForAllResults[i] />
		</cfloop>
		
		<cfif structkeyexists(stReturn.data,"rows")>
			<cfset stReturn.results = createResultQuery(stReturn.data.columnHeaders,stReturn.data.rows) />
		</cfif>
		
		<cfreturn stReturn />
	</cffunction>

	<cffunction name="getDataAll" access="public" output="false" returntype="struct">
		<!--- Same arguments as getGAData, without maxResults --->
		
		<cfset var stNewData = structnew() />
		<cfset var stData = structnew() />
		
		<cfset arguments.startIndex = 1 />
		<cfset arguments.maxResults = 1000 />
		<cfset stNewData = getData(argumentCollection=arguments) />
		
		<cfset stData.aggregates = duplicate(stNewData.aggregates) />
		<cfset stData.results = stNewData.results />
		
		<cfloop condition="stNewData.results.recordcount and stNewData.startIndex + arguments.maxResults lte stNewData.totalResults">
			<cfset arguments.startIndex = arguments.startIndex + arguments.maxResults />
			<cfset stNewData = getData(argumentCollection=arguments) />
			<cfquery dbtype="query" name="stData.results">
				select	#stData.results.columnlist#
				from	stData.results
				
				UNION
				
				select	#stNewData.results.columnlist#
				from	stNewData.results
			</cfquery>
		</cfloop>
		
		<cfset stData.totalResults = stData.results.recordcount />
		
		<cfreturn stData />
	</cffunction>
	
</cfcomponent>