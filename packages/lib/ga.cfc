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
		<cfset var temp = "" />
		
		<cfif not structkeyexists(application.stPlugins.googleanalytics,request.fc.ga.host)>
			<cfset temp = application.fapi.getContentType(typename="gaSetting").getSettings(request.fc.ga.host) />
			<cfset application.stPlugins.googleanalytics[request.fc.ga.host] = temp.objectid />
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
		<cfset var trackableURL = "" />
		<cfset var stNav = structnew() />
		<cfset var stSettings = getSettings() />
		<cfset var urlVar = "" />
		
		<cfimport taglib="/farcry/core/tags/navajo" prefix="nj" />
		
		<cfif not structkeyexists(request.fc.ga,"stObject") and isDefined("request.stObj.objectID") and isValid("uuid",request.stObj.objectID)>
			<cfset request.fc.ga.stObject = request.stObj />
		</cfif>
		
		<cfif structkeyexists(request.fc.ga,"url")>
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
		
		<cfloop list="#stSettings.urlWhiteList#" index="urlVar">
			<cfif structkeyexists(url,urlVar) and not refindnocase("[&?]#urlVar#=",trackableURL)>
				<cfif find("?",trackableURL)>
					<cfset trackableURL = "#trackableURL#&#urlVar#=#url[urlVar]#" />
				<cfelse>
					<cfset trackableURL = "#trackableURL#?#urlVar#=#url[urlVar]#" />
				</cfif>
			</cfif>
		</cfloop>
		
		<cfreturn trackableURL />
	</cffunction>
	
</cfcomponent>