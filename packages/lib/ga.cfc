<cfcomponent displayname="Google Analytics" hint="Google analytics library" output="false">
	
	<cfset this.cvScopes = structnew() />
	<cfset this.cvScopes.visitor = 1 />
	<cfset this.cvScopes.session = 2 />
	<cfset this.cvScopes.page = 3 />
	
	<cffunction name="initializeRequest" access="public" output="false" returntype="void" hint="Sets up the request to collect tracking information">
		
		<cfparam name="request.fc" default="#structnew()#" />
		<cfset request.fc.ga = structnew() />
		<cfset request.fc.ga.aCustomVars = arraynew(1) />
		<cfset arrayset(request.fc.ga.aCustomVars,1,5,"") />
		<cfset request.fc.ga.host = cgi.http_host />
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
		
		<cfloop from="1" to="#arraylen(request.fc.ga.aCustomVars)#" index="i">
			<cfif isstruct(request.fc.ga.aCustomVars[i])>
				<cfset queryaddrow(q) />
				<cfset querysetcell(q,"slot",i) />
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
	
	<cffunction name="getSettings" access="public" output="false" returntype="struct" hint="Returns the tracking settings to use for this request (uses the request host)">
		<cfset var temp = structNew() />
		
		<cfif not structkeyexists(application.stPlugins.googleanalytics,request.fc.ga.host)>
			<cfset temp = application.fapi.getContentType(typename="gaSetting").getSettings(request.fc.ga.host) />
			<cfif isDefined("temp.objectid")>
				<cfset application.stPlugins.googleanalytics[request.fc.ga.host] = temp.objectid />
			</cfif>
			<cfreturn temp />
		<cfelse>
			<cfreturn application.fapi.getContentObject(typename="gaSetting",objectid=application.stPlugins.googleanalytics[request.fc.ga.host]) />
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
		<cfset var stSettings = getSettings() />
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
			<cfelse>
				<cfset trackableURL = application.fapi.getLink(objectid=request.fc.ga.stObject.objectid) />
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
	
	
	<cffunction name="parseProxy" access="private" output="false" returntype="struct">
		<cfargument name="proxy" type="string" required="true" />
		
		<cfset var stResult = structnew() />
		<cfset var login = "" />
		<cfset var address = "" />
		
		<cfif len(arguments.proxy)>
			<cfif listlen(arguments.proxy,"@") eq 2>
				<cfset login = listfirst(arguments.proxy,"@") />
				<cfset stResult.proxyUser = listfirst(login,":") />
				<cfset stResult.proxyPassword = listlast(login,":") />
			</cfif>
			<cfset address = listlast(arguments.proxy,"@") />
			<cfset stResult.proxyServer = listfirst(address,":") />
			<cfif listlen(stResult.server,":") eq 2>
				<cfset stResult.proxyPort = listlast(address,":") />
			<cfelse>
				<cfset stResult.proxyPort = "80" />
			</cfif>
		</cfif>
		
		<cfreturn stResult />
	</cffunction>

	<cffunction name="getAuthorisationURL" access="public" output="false" returntype="string">
		<cfargument name="clientid" type="string" required="true" />
		<cfargument name="redirectURL" type="string" required="true" />
		<cfargument name="accessType" type="string" required="false" default="offline" />
		<cfargument name="state" type="string" required="false" default="" />
		
		<cfreturn "https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=#arguments.clientid#&redirect_uri=#urlencodedformat(arguments.redirectURL)#&scope=https://www.googleapis.com/auth/analytics.readonly&access_type=#arguments.accesstype#&state=#urlencodedformat(arguments.state)#&approval_prompt=force" />
	</cffunction>
	
	<cffunction name="getRefreshToken" access="public" output="false" returntype="string">
		<cfargument name="authorizationCode" type="string" required="true" />
		<cfargument name="clientID" type="string" required="true" />
		<cfargument name="clientSecret" type="string" required="true" />
		<cfargument name="redirectURL" type="string" required="true" />
		<cfargument name="proxy" type="string" required="false" default="" />
		
		<cfset var cfhttp = structnew() />
		<cfset var stResult = structnew() />
		<cfset var stAttr = parseProxy(arguments.proxy) />
		
		<cfset stAttr.url = "https://accounts.google.com/o/oauth2/token" />
		<cfset stAttr.method = "POST" />
		
		<cfhttp attributeCollection="#stAttr#">
			<cfhttpparam type="formfield" name="code" value="#arguments.authorizationCode#" />
			<cfhttpparam type="formfield" name="client_id" value="#arguments.clientID#" />
			<cfhttpparam type="formfield" name="client_secret" value="#arguments.clientSecret#" />
			<cfhttpparam type="formfield" name="redirect_uri" value="#arguments.redirectURL#" />
			<cfhttpparam type="formfield" name="grant_type" value="authorization_code" />
		</cfhttp>
		
		<cfif not cfhttp.statuscode eq "200 OK">
			<cfthrow message="Error accessing Google API: #cfhttp.statuscode# (#cfhttp.filecontent#)" detail="#cfhttp.filecontent#" />
		</cfif>
		
		<cfset stResult = deserializeJSON(cfhttp.FileContent.toString()) />
		
		<cfset this.access_token = stResult.access_token />
		<cfset this.access_token_expires = dateadd("s",stResult.expires_in,now()) />
		
		<cfreturn stResult.refresh_token />
	</cffunction>
	
	<cffunction name="getAccessToken" access="public" output="false" returntype="string">
		<cfargument name="refreshToken" type="string" required="true" />
		<cfargument name="clientID" type="string" required="true" />
		<cfargument name="clientSecret" type="string" required="true" />
		<cfargument name="proxy" type="string" required="false" default="" />
		<cfargument name="force" type="boolean" required="false" default="false" />
		
		<cfset var cfhttp = structnew() />
		<cfset var stResult = structnew() />
		<cfset var stAttr = "" />
		
		<cfif not isdefined("this.access_token") or not isdefined("this.access_token_expires") or datecompare(this.access_token_expires,now()) lt 0 or arguments.force>
			<cfset stAttr = parseProxy(arguments.proxy) />
			
			<cfset stAttr.url = "https://accounts.google.com/o/oauth2/token" />
			<cfset stAttr.method = "POST" />
			
			<cfhttp attributeCollection="#stAttr#">
				<cfhttpparam type="formfield" name="refresh_token" value="#arguments.refreshToken#" />
				<cfhttpparam type="formfield" name="client_id" value="#arguments.clientID#" />
				<cfhttpparam type="formfield" name="client_secret" value="#arguments.clientSecret#" />
				<cfhttpparam type="formfield" name="grant_type" value="refresh_token" />
			</cfhttp>
			
			<cfif not cfhttp.statuscode eq "200 OK">
				<cfthrow message="Error accessing Google API: #cfhttp.statuscode#" detail="#cfhttp.filecontent#" />
			</cfif>
			
			<cfset stResult = deserializeJSON(cfhttp.FileContent.toString()) />
			
			<cfset this.access_token = stResult.access_token />
			<cfset this.access_token_expires = dateadd("s",stResult.expires_in,now()) />
		</cfif>
		
		<cfreturn this.access_token />
	</cffunction>
	
	<cffunction name="getAccounts" access="public" output="false" returntype="query">
		<cfargument name="accessToken" type="string" required="true" />
		<cfargument name="proxy" type="string" required="false" default="" />
		
		<cfset var cfhttp = structnew() />
		<cfset var stResult = structnew() />
		<cfset var qAccounts = querynew("id,name") />
		<cfset var i = 0 />
		<cfset var stAttr = parseProxy(arguments.proxy) />
		
		<cfset stAttr.url = "https://www.googleapis.com/analytics/v3/management/accounts" />
		<cfset stAttr.method = "GET" />
		
		<cfhttp attributeCollection="#stAttr#">
			<cfhttpparam type="header" name="Authorization" value="Bearer #arguments.accessToken#" />
		</cfhttp>
		
		<cfif not cfhttp.statuscode eq "200 OK">
			<cfthrow message="Error accessing Google API: #cfhttp.statuscode#" detail="#cfhttp.filecontent#" />
		</cfif>
		
		<cfset stResult = deserializeJSON(cfhttp.filecontent.toString()) />
		<cfif StructKeyExists(stResult, "items") >
			<cfloop from="1" to="#arraylen(stResult.items)#" index="i">
				<cfset queryaddrow(qAccounts) />
				<cfset querysetcell(qAccounts,"id",stResult.items[i].id) />
				<cfset querysetcell(qAccounts,"name",stResult.items[i].name) />
			</cfloop>
		</cfif>
		<cfquery dbtype="query" name="qAccounts">
			select * from qAccounts order by [name] asc
		</cfquery>
		
		<cfreturn qAccounts />
	</cffunction>
	
	<cffunction name="getWebProperties" access="public" output="false" returntype="query">
		<cfargument name="accountID" type="string" required="true" />
		<cfargument name="accessToken" type="string" required="true" />
		<cfargument name="proxy" type="string" required="false" default="" />
		
		<cfset var cfhttp = structnew() />
		<cfset var stResult = structnew() />
		<cfset var qWebProperties = querynew("id,name") />
		<cfset var i = 0 />
		<cfset var stAttr = parseProxy(arguments.proxy) />
		
		<cfset stAttr.url = "https://www.googleapis.com/analytics/v3/management/accounts/#arguments.accountID#/webproperties" />
		<cfset stAttr.method = "GET" />
		
		<cfhttp attributeCollection="#stAttr#">
			<cfhttpparam type="header" name="Authorization" value="Bearer #arguments.accessToken#" />
		</cfhttp>
		
		<cfif not cfhttp.statuscode eq "200 OK">
			<cfthrow message="Error accessing Google API: #cfhttp.statuscode#" detail="#cfhttp.filecontent#" />
		</cfif>
		
		<cfset stResult = deserializeJSON(cfhttp.filecontent.toString()) />
		<cfloop from="1" to="#arraylen(stResult.items)#" index="i">
			<cfset queryaddrow(qWebProperties) />
			<cfset querysetcell(qWebProperties,"id",stResult.items[i].id) />
			<cfset querysetcell(qWebProperties,"name",stResult.items[i].websiteUrl) />
		</cfloop>
		
		<cfquery dbtype="query" name="qWebProperties">
			select * from qWebProperties order by [name] asc
		</cfquery>
		
		<cfreturn qWebProperties />
	</cffunction>
	
	<cffunction name="getProfiles" access="public" output="false" returntype="query">
		<cfargument name="accountID" type="string" required="true" />
		<cfargument name="webPropertyID" type="string" required="true" />
		<cfargument name="accessToken" type="string" required="true" />
		<cfargument name="proxy" type="string" required="false" default="" />
		
		<cfset var cfhttp = structnew() />
		<cfset var stResult = structnew() />
		<cfset var qProfiles = querynew("id,name") />
		<cfset var i = 0 />
		<cfset var stAttr = parseProxy(arguments.proxy) />
		
		<cfset stAttr.url = "https://www.googleapis.com/analytics/v3/management/accounts/#arguments.accountID#/webproperties/#arguments.webPropertyID#/profiles" />
		<cfset stAttr.method = "GET" />
		
		<cfhttp attributeCollection="#stAttr#">
			<cfhttpparam type="header" name="Authorization" value="Bearer #arguments.accessToken#" />
		</cfhttp>
		
		<cfif not cfhttp.statuscode eq "200 OK">
			<cfthrow message="Error accessing Google API: #cfhttp.statuscode#" detail="#cfhttp.filecontent#" />
		</cfif>
		
		<cfset stResult = deserializeJSON(cfhttp.filecontent.toString()) />
		<cfloop from="1" to="#arraylen(stResult.items)#" index="i">
			<cfset queryaddrow(qProfiles) />
			<cfset querysetcell(qProfiles,"id",stResult.items[i].id) />
			<cfset querysetcell(qProfiles,"name",stResult.items[i].name) />
		</cfloop>
		
		<cfquery dbtype="query" name="qProfiles">
			select * from qProfiles order by [name] asc
		</cfquery>
		
		<cfreturn qProfiles />
	</cffunction>
	
	
	
	<cffunction name="getDataAll" access="public" output="false" returntype="struct">
		<!--- Same arguments as getData, without maxResults --->
		
		<cfset var stNewData = structnew() />
		
		<cfset arguments.startIndex = 1 />
		<cfset arguments.maxResults = 1000 />
		<cfset stNewData = getData(argumentCollection=arguments) />
		<cfset stData = stNewData />
		
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
		
		<cfreturn stData />
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
		<cfargument name="proxy" type="string" required="false" default="" />
		
		<cfargument name="profileID" type="string" required="true" />
		<cfargument name="accessToken" type="string" required="true" />
		
		<cfset var cfhttp = structnew() />
		<cfset var stResult = structnew() />
		<cfset var gaurl = "" />
		<cfset var i = 0 />
		<cfset var stReturn = structnew() />
		<cfset var stAttr = "" />
		
		<cfset stReturn.results = querynew("empty") />
		<cfset stReturn.args = duplicate(arguments) />
		
		<cfif len(arguments.profileID) and len(arguments.accessToken)>
			<cfset gaurl = "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:#arguments.profileid#" />
			
			<cfif structkeyexists(arguments,"dimensions")><cfset gaurl = "#gaurl#&dimensions=#arguments.dimensions#" /></cfif>
			<cfset gaurl = "#gaurl#&metrics=#arguments.metrics#" />
			<cfif structkeyexists(arguments,"sort")><cfset gaurl = "#gaurl#&sort=#arguments.sort#" /></cfif>
			<cfif structkeyexists(arguments,"filters")><cfset gaurl = "#gaurl#&filters=#urlencodedformat(arguments.filters)#" /></cfif>
			<cfif structkeyexists(arguments,"segment")><cfset gaurl = "#gaurl#&segment=#arguments.segment#" /></cfif>
			<cfset gaurl = "#gaurl#&start-date=#dateformat(arguments.startDate,'yyyy-mm-dd')#" />
			<cfset gaurl = "#gaurl#&end-date=#dateformat(arguments.endDate,'yyyy-mm-dd')#" />
			<cfif structkeyexists(arguments,"startIndex")><cfset gaurl = "#gaurl#&start-index=#arguments.startIndex#" /></cfif>
			<cfif structkeyexists(arguments,"maxResults")><cfset gaurl = "#gaurl#&max-results=#arguments.maxResults#" /></cfif>
			
			<cfset gaurl = "#gaurl#&v=2&prettyprint=false" />
			
			<cfparam name="arguments.dimensions" default="" />
			
			<cfset stAttr = parseProxy(arguments.proxy) />
			
			<cfset stAttr.url = gaurl />
			<cfset stAttr.method = "GET" />
			
			<cfhttp attributeCollection="#stAttr#">
				<cfhttpparam type="header" name="Authorization" value="Bearer #arguments.accessToken#" />
			</cfhttp>
			
			<cfif not cfhttp.statuscode eq "200 OK">
				<cfthrow message="Error accessing Google API: #cfhttp.statuscode# - #gaurl#" detail="#cfhttp.filecontent#" />
			<cfelse>
				<cfset stReturn.data = deserializeJSON(cfhttp.filecontent) />
				<cfset stReturn.id = stReturn.data.id />
				<cfset stReturn.totalResults = stReturn.data.totalResults />
				<cfset stReturn.startIndex = stReturn.data.query["start-index"] />
				
				<cfset stReturn.aggregates = structnew() />
				<cfloop collection="#stReturn.data.totalsForAllResults#" item="i">
					<cfset stReturn.aggregates[i] = stReturn.data.totalsForAllResults[i] />
				</cfloop>
				
				<cfset stArgs.columns = stReturn.data.columnHeaders />
				<cfif structkeyexists(stReturn.data,"rows")>
					<cfset stArgs.results = stReturn.data.rows />
				</cfif>
				<cfif structkeyexists(arguments,"startdate") and structkeyexists(arguments,"enddate")>
					<cfset stArgs.startDate = arguments.startDate />
					<cfset stArgs.endDate = arguments.endDate />
				</cfif>
				<cfset stReturn.results = createResultQuery(argumentCollection=stArgs) />
			</cfif>
		</cfif>
		
		<cfreturn stReturn />
	</cffunction>
	
	<cffunction name="createResultQuery" access="private" output="false" returntype="query" hint="Creates a result query for the specified dimensions and metrics">
		<cfargument name="columns" type="array" required="true" />
		<cfargument name="results" type="any" required="false" />
		<cfargument name="startDate" type="date" required="false" />
		<cfargument name="endDate" type="date" required="false" />
		
		<cfset var columnnames = "" />
		<cfset var columntypes = "" />
		<cfset var thiscolumn = "" />
		<cfset var qResult = "" />
		<cfset var i = 0 />
		<cfset var j = 0 />
		<cfset var thisdate = "" />
		<cfset var q = "" />
		
		<cfloop from="1" to="#arraylen(arguments.columns)#" index="i">
			<cfset thiscolumn = listlast(arguments.columns[i].name,":") />
			<cfset columnnames = listappend(columnnames,thiscolumn) />
			
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
		
		<cfif listfindnocase(columnnames,"date")>
			<cfset columnnames = listappend(columnnames,"year,quarter,month,week,dayofweek") />
			<cfset columntypes = listappend(columntypes,"Integer,Integer,Integer,Integer,Integer") />
		</cfif>
		
		<cfset qResult = querynew(columnnames,columntypes) />
		
		<cfif structkeyexists(arguments,"results")>
			<cfloop from="1" to="#arraylen(arguments.results)#" index="i">
				<cfset queryaddrow(qResult) />
				<cfloop from="1" to="#arraylen(arguments.results[i])#" index="j">
					<cfset setResultValue(qResult,listlast(arguments.columns[j].name,":"),arguments.results[i][j]) />
				</cfloop>
			</cfloop>
		</cfif>
		
		
		<cfreturn qResult />
	</cffunction>
	
	<cffunction name="setResultValue" access="private" output="false" returntype="void" hint="Sets a value in a result query, according to the relevant type">
		<cfargument name="query" type="query" required="true" hint="The result query" />
		<cfargument name="key" type="string" required="true" hint="The value name" />
		<cfargument name="value" type="string" required="true" hint="The value" />
		<cfargument name="row" type="numeric" required="false" hint="Row to update" />
		
		<cfset var curval = "" />
		
		<cfset arguments.key = listlast(arguments.key,":") />
		
		<cfif not structkeyexists(arguments,"row")>
			<cfset row = arguments.query.recordcount />
		</cfif>
		
		<cfswitch expression="#arguments.key#">
			<cfcase value="date">
				<cfset curval = arguments.query[arguments.key][arguments.row] />
				<cfif isdate(curval)>
					<cfset curval = createdatetime(left(arguments.value,"4"),mid(arguments.value,5,2),right(arguments.value,2),hour(curval),0,0) />
				<cfelse>
					<cfset curval = createdatetime(left(arguments.value,"4"),mid(arguments.value,5,2),right(arguments.value,2),0,0,0) />
				</cfif>
				<cfset querysetcell(arguments.query,arguments.key,curval,arguments.row) />
				<cfset querysetcell(arguments.query,"year",year(curval),arguments.row) />
				<cfset querysetcell(arguments.query,"quarter",quarter(curval),arguments.row) />
				<cfset querysetcell(arguments.query,"month",month(curval),arguments.row) />
				<cfset querysetcell(arguments.query,"week",week(curval),arguments.row) />
				<cfset querysetcell(arguments.query,"dayofweek",dayofweek(curval),arguments.row) />
			</cfcase>
			<cfcase value="hour">
				<cfset querysetcell(arguments.query,arguments.key,arguments.value,arguments.row) />
				
				<cfif listfindnocase(arguments.query.columnlist,"date")>
					<cfset curval = arguments.query["date"][arguments.row] />
					<cfif isdate(curval)>
						<cfset querysetcell(arguments.query,"date",createdatetime(year(curval),month(curval),day(curval),arguments.value,0,0),arguments.row) />
					<cfelse>
						<cfset querysetcell(arguments.query,"date",createdatetime(1970,1,1,arguments.value,0,0),arguments.row) />
					</cfif>
				</cfif>
			</cfcase>
			<cfdefaultcase>
				<cfset querysetcell(arguments.query,arguments.key,arguments.value,arguments.row) />
			</cfdefaultcase>
		</cfswitch>
	</cffunction>
	
</cfcomponent>