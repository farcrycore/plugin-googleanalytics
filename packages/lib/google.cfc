<cfcomponent>
	
	<cffunction name="init" access="public" output="false" returntype="any">
		
		<cfset this.access_tokens = {} />

		<cfreturn this />
	</cffunction>

	<cffunction name="getAccessConfig" access="public" output="false" returntype="struct">
		<cfargument name="stObject" type="struct" required="true" />
		<cfargument name="stMetadata" type="struct" required="true" />

		<cfset accessConfig = {} />

		<!--- client id --->
		<cfif refindnocase("^config\.", arguments.stMetadata.ftClientID)>
			<cfset accessConfig["clientID"] = application.fapi.getConfig(listGetAt(arguments.stMetadata.ftClientID, 2, "."), listGetAt(arguments.stMetadata.ftClientID, 3, ".")) />
		<cfelse>
			<cfset accessConfig["clientID"] = arguments.stObject[arguments.stMetadata.ftClientID] />
		</cfif>

		<!--- client secret --->
		<cfif refindnocase("^config\.", arguments.stMetadata.ftClientSecret)>
			<cfset accessConfig["clientSecret"] = application.fapi.getConfig(listGetAt(arguments.stMetadata.ftClientSecret, 2, "."), listGetAt(arguments.stMetadata.ftClientSecret, 3, ".")) />
		<cfelse>
			<cfset accessConfig["clientSecret"] = arguments.stObject[arguments.stMetadata.ftClientSecret] />
		</cfif>

		<!--- proxy --->
		<cfif len(arguments.stMetadata.ftProxy)>
			<cfif refindnocase("^config\.", arguments.stMetadata.ftProxy)>
				<cfset accessConfig["proxy"] = application.fapi.getConfig(listGetAt(arguments.stMetadata.ftProxy, 2, "."), listGetAt(arguments.stMetadata.ftProxy, 3, ".")) />
			<cfelse>
				<cfset accessConfig["proxy"] = arguments.stObject[arguments.stMetadata.ftProxy] />
			</cfif>
		<cfelse>
			<cfset accessConfig["proxy"] = "" />
		</cfif>

		<!--- refresh token --->
		<cfset accessConfig["refreshToken"] = listrest(arguments.stObject[arguments.stMetadata.name], ":") />

		<cfreturn accessConfig />
	</cffunction>

	<cffunction name="parseProxy" access="public" output="false" returntype="struct">
		<cfargument name="proxy" type="string" required="true" />

		<cfset stResult = {
			"user" = "",
			"password" = "",
			"domain" = "",
			"port" = "80"
		} />
		
		<cfif len(arguments.proxy)>
			<cfif listlen(arguments.proxy,"@") eq 2>
				<cfset stResult["login"] = listfirst(arguments.proxy,"@") />
				<cfset stResult["user"] = listfirst(stResult.login,":") />
				<cfset stResult["password"] = listlast(stResult.login,":") />
			<cfelse>
				<cfset stResult["user"] = "" />
				<cfset stResult["password"] = "" />
			</cfif>

			<cfset stResult["server"] = listlast(arguments.proxy,"@") />
			<cfset stResult["domain"] = listfirst(stResult.server,":") />

			<cfif listlen(stResult["server"],":") eq 2>
				<cfset stResult["port"] = listlast(stResult.server,":") />
			<cfelse>
				<cfset stResult["port"] = "80" />
			</cfif>
		</cfif>
		
		<cfreturn stResult />
	</cffunction>

	<!---
		From http://code.google.com/apis/analytics/docs/gdata/v3/gdataAuthorization.html: 
	    1) When you create your application, you register it with Google. Google then provides information you'll need later, such as a client ID and a client secret.
	    2) Activate the Google Analytics API in the Services pane of the Google APIs Console. (If it isn't listed in the Console, then skip this step.)
	    3) When your application needs access to user data, it asks Google for a particular scope of access. ***
	    4) Google displays an OAuth dialog to the user, asking them to authorize your application to request some of their data.
	    5) If the user approves, then Google gives your application a short-lived access token.
	    6) Your application requests user data, attaching the access token to the request.
	    7) If Google determines that your request and the token are valid, it returns the requested data.
	--->
	<cffunction name="getAuthorisationURL" access="public" output="false" returntype="string">
		<cfargument name="clientID" type="string" required="true" />
		<cfargument name="redirectURL" type="string" required="true" />
		<cfargument name="accessType" type="string" default="offline" />
		<cfargument name="scope" type="string" default="https://www.googleapis.com/auth/userinfo.profile" />
		<cfargument name="state" type="string" default="" />

		<cfset authURL = "https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=#arguments.clientid#&redirect_uri=#urlencodedformat(arguments.redirectURL)#&scope=#arguments.scope#&access_type=#arguments.accesstype#&state=#urlencodedformat(arguments.state)#&approval_prompt=force" />

		<cfreturn authURL />
	</cffunction>
	
	<cffunction name="getRefreshToken" access="public" output="false" returntype="string">
		<cfargument name="authorizationCode" type="string" required="true" />
		<cfargument name="clientID" type="string" required="true" />
		<cfargument name="clientSecret" type="string" required="true" />
		<cfargument name="redirectURL" type="string" required="true" />
		<cfargument name="proxy" type="string" required="true" />

		<cfset cfhttp = {} />
		<cfset stResult = {} />
		<cfset stProxy = parseProxy(arguments.proxy) />
		<cfset stDetail = "" />
		
		<cfhttp url="https://accounts.google.com/o/oauth2/token" method="POST" proxyServer="#stProxy.domain#" proxyPort="#stProxy.port#" proxyUser="#stProxy.user#" proxyPassword="#stProxy.password#">
			<cfhttpparam type="formfield" name="code" value="#arguments.authorizationCode#" />
			<cfhttpparam type="formfield" name="client_id" value="#arguments.clientID#" />
			<cfhttpparam type="formfield" name="client_secret" value="#arguments.clientSecret#" />
			<cfhttpparam type="formfield" name="redirect_uri" value="#arguments.redirectURL#" />
			<cfhttpparam type="formfield" name="grant_type" value="authorization_code" />	
		</cfhttp>
		
		<cfif not cfhttp.statuscode eq "200 OK">
			<cfif request.mode.debug>
				<cfset stDetail = serializeJSON({ "arguments" = duplicate(arguments) }) />
			</cfif>
			<cfthrow message="Error retrieving refresh token: #cfhttp.statuscode# (#cfhttp.filecontent#)" detail="#stDetail#" />
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
		<cfargument name="proxy" type="string" required="true" />

		<cfset cfhttp = {} />
		<cfset stResult = {} />
		<cfset stProxy = parseProxy(arguments.proxy) />
		
		<cfif not structkeyexists(this.access_tokens, arguments.refreshToken) or datecompare(this.access_tokens[arguments.refreshToken].expires,now()) lt 0>
			<cfhttp url="https://accounts.google.com/o/oauth2/token" method="POST" proxyServer="#stProxy.domain#" proxyPort="#stProxy.port#" proxyUser="#stProxy.user#" proxyPassword="#stProxy.password#">
				<cfhttpparam type="formfield" name="refresh_token" value="#arguments.refreshToken#" />
				<cfhttpparam type="formfield" name="client_id" value="#arguments.clientID#" />
				<cfhttpparam type="formfield" name="client_secret" value="#arguments.clientSecret#" />
				<cfhttpparam type="formfield" name="grant_type" value="refresh_token" />
			</cfhttp>
			
			<cfif not cfhttp.statuscode eq "200 OK">
				<cfthrow message="Error accessing Google API: #cfhttp.statuscode#" />
			</cfif>
			
			<cfset stResult = deserializeJSON(cfhttp.FileContent.toString()) />
			
			<cfset this.access_tokens[arguments.refreshToken] = {
				"token" = stResult.access_token,
				"expires" = dateadd("s",stResult.expires_in,now())
			} />
		</cfif>
		
		<cfreturn this.access_tokens[arguments.refreshToken].token />
	</cffunction>

	<cffunction name="makeRequest" access="public" output="false" returntype="any">
		<cfargument name="accessConfig" type="struct" required="true" />
		<cfargument name="resource" type="string" required="true" />
		<cfargument name="method" type="string" required="false" default="" />
		<cfargument name="stQuery" type="struct" required="false" default="#structnew()#" />
		<cfargument name="stData" type="struct" required="false" default="#structnew()#" />
		<cfargument name="format" type="string" required="false" default="json" />
		<cfargument name="timeout" type="numeric" required="false" default="30" />

		<cfset stProxy = parseProxy(arguments.accessConfig.proxy) />
		<cfset accessToken = getAccessToken(argumentCollection=arguments.accessConfig) />
		<cfset result = "" />
		<cfset item = "" />
		<cfset resourceURL = arguments.resource />

		<cfloop list="#structKeyList(arguments.stQuery)#" index="item">
			<cfif find("?", resourceURL)>
				<cfset resourceURL = resourceURL & "&" />
			<cfelse>
				<cfset resourceURL = resourceURL & "?" />
			</cfif>

			<cfset resourceURL = resourceURL & URLEncodedFormat(item) & "=" & URLEncodedFormat(arguments.stQuery[item]) />
		</cfloop>

		<cfif arguments.method eq "">
			<cfif structisempty(arguments.stData)>
				<cfset arguments.method = "GET" />
			<cfelse>
				<cfset arguments.method = "POST" />
			</cfif>
		</cfif>

		<cfhttp method="#arguments.method#" url="https://www.googleapis.com#resourceURL#" proxyServer="#stProxy.domain#" proxyPort="#stProxy.port#" proxyUser="#stProxy.user#" proxyPassword="#stProxy.password#" timeout="#arguments.timeout#">
			<cfhttpparam type="header" name="Authorization" value="Bearer #accessToken#" />

			<cfif not structisempty(arguments.stData)>
				<cfhttpparam type="header" name="Content-Type" value="application/json" />
				<cfhttpparam type="body" value="#serializeJSON(arguments.stData)#" />
			</cfif>
		</cfhttp>
		
		<cfif not refindnocase("^20. ",cfhttp.statuscode)>
			<cfthrow message="Error accessing Google API: #cfhttp.statuscode#" detail="#serializeJSON({ 
				'resource' = arguments.resource,
				'method' = arguments.method,
				'query_string' = arguments.stQuery,
				'body' = arguments.stData,
				'resourceURL' = resourceURL,
				'response' = isjson(cfhttp.filecontent.toString()) ? deserializeJSON(cfhttp.filecontent.toString()) : cfhttp.filecontent.toString()
			})#" />
		</cfif>
		
		<cfset result = cfhttp.filecontent.toString() />

		<cfif len(result)>
			<cfswitch expression="#arguments.format#">
				<cfcase value="json">
					<cfset result = deserializeJSON(result) />
				</cfcase>
			</cfswitch>
		<cfelse>
			<cfset result = {} />
		</cfif>

		<cfreturn result />
	</cffunction>

	<cffunction name="itemsToQuery" access="public" output="false" returntype="query">
		<cfargument name="items" type="array" required="true" />
		<cfargument name="order" type="string" required="false" />

		<cfset q = "" />
		<cfset item = {} />
		<cfset columnNames = [] />
		<cfset columnTypes = [] />
		<cfset col = "" />
		<cfset queryService = "" />

		<cfloop array="#arguments.items#" index="item">
			<cfif not isQuery(q)>
				<cfloop list="#structKeyList(item)#" index="col">
					<cfif isSimpleValue(item[col])>
						<cfset arrayAppend(columnNames,col) />
						<cfswitch expression="#col#">
							<cfcase value="created,updated" delimiters=",">
								<cfset arrayAppend(columnTypes,"date") />
							</cfcase>
							<cfdefaultcase>
								<cfset arrayAppend(columnTypes,"varchar") />
							</cfdefaultcase>
						</cfswitch>
					</cfif>
				</cfloop>
				<cfset q = querynew(columnNames, columnTypes) />
			</cfif>

			<cfset queryAddRow(q) />

			<cfloop array="#columnNames#" index="col">
				<cfif structKeyExists(item,col)>
					<cfset querySetCell(q,col,item[col]) />
				</cfif>
			</cfloop>
		</cfloop>

		<cfif structKeyExists(arguments,"order") and len(arguments.order)>
			<cfquery dbtype="query" name="q">
				SELECT * FROM q ORDER BY #arguments.order#
			</cfquery>
		</cfif>

		<cfreturn q />
	</cffunction>

	<!---
	 Serialize native ColdFusion objects into a JSON formated string.
	 
	 @param arg 	 The data to encode. (Required)
	 @<cfreturn Returns a string. 
	 @author Jehiah Czebotar (jehiah@gmail.com) 
	 @version 2, June 27, 2008 
	--->
	<cffunction name="jsonencode" access="public" output="false" returntype="string">
		<cfargument name="data" type="any" required="true" />  
		<cfargument name="queryFormat" type="string" required="false" default="query" />
		<cfargument name="queryKeyCase" type="string" required="false" default="lower" />
		<cfargument name="stringNumbers" type="boolean" required="false" default="false" />
		<cfargument name="formatDates" type="boolean" required="false" default="false" />
		<cfargument name="columnListFormat" type="string" required="false" default="string" />

		<!--- VARIABLE DECLARATION --->
		<cfset jsonString = "" />
		<cfset tempVal = "" />
		<cfset arKeys = "" />
		<cfset colPos = 1 />
		<cfset i = 1 />
		<cfset column = "" />
		<cfset datakey = "" />
		<cfset recordcountkey = "" />
		<cfset columnlist = "" />
		<cfset columnlistkey = "" />
		<cfset dJSONString = "" />
		<cfset escapeToVals = "\\,\"",\/,\b,\t,\n,\f,\r" />
		<cfset escapeVals = "\,"",/,#Chr(8)#,#Chr(9)#,#Chr(10)#,#Chr(12)#,#Chr(13)#" />
		
		<cfset _data = arguments.data />

		<!--- BOOLEAN --->
		<cfif IsBoolean(_data) AND NOT IsNumeric(_data) AND NOT ListFindNoCase("Yes,No", _data)>
			<cfreturn LCase(ToString(_data)) />
		
		<!--- NUMBER --->
		<cfelseif NOT stringNumbers AND IsNumeric(_data) AND NOT REFind("^0+[^\.]",_data)>
			<cfreturn ToString(_data) />
		
		<!--- DATE --->
		<cfelseif IsDate(_data) AND arguments.formatDates>
			<cfreturn '"#DateFormat(_data, "medium")# #TimeFormat(_data, "medium")#"' />
		
		<!--- STRING --->
		<cfelseif IsSimpleValue(_data)>
			<cfreturn '"' & ReplaceList(_data, escapeVals, escapeToVals) & '"' />
		
		<!--- ARRAY --->
		<cfelseif IsArray(_data)>
			<cfset dJSONString = createObject('java','java.lang.StringBuffer').init("") />
			<cfloop array="#_data#" index="i">
				<cfset tempVal = jsonencode( i, arguments.queryFormat, arguments.queryKeyCase, arguments.stringNumbers, arguments.formatDates, arguments.columnListFormat ) />
				<cfif dJSONString.toString() EQ "">
					<cfset dJSONString.append(tempVal) />
				<cfelse>
					<cfset dJSONString.append("," & tempVal) />
				</cfif>
			</cfloop>
			
			<cfreturn "[" & dJSONString.toString() & "]" />
		
		<!--- STRUCT --->
		<cfelseif IsStruct(_data)>
			<cfset dJSONString = createObject('java','java.lang.StringBuffer').init("") />
			<cfset arKeys = StructKeyArray(_data) />
			<cfloop array="#arKeys#" index="i">
				<cfset tempVal = jsonencode( _data[ i ], arguments.queryFormat, arguments.queryKeyCase, arguments.stringNumbers, arguments.formatDates, arguments.columnListFormat ) />
				<cfif dJSONString.toString() EQ "">
					<cfset dJSONString.append('"' & i & '":' & tempVal) />
				<cfelse>
					<cfset dJSONString.append("," & '"' & i & '":' & tempVal) />
				</cfif>
			</cfloop>
			
			<cfreturn "{" & dJSONString.toString() & "}" />
		
		<!--- QUERY --->
		<cfelseif IsQuery(_data)>
			<cfset dJSONString = createObject('java','java.lang.StringBuffer').init("") />
			
			<!--- Add query meta data --->
			<cfif arguments.queryKeyCase EQ "lower">
				<cfset recordcountKey = "recordcount" />
				<cfset columnlistKey = "columnlist" />
				<cfset columnlist = LCase(_data.columnlist) />
				<cfset dataKey = "data" />
			<cfelse>
				<cfset recordcountKey = "RECORDCOUNT" />
				<cfset columnlistKey = "COLUMNLIST" />
				<cfset columnlist = _data.columnlist />
				<cfset dataKey = "data" />
			</cfif>
			
			<cfset dJSONString.append('"#recordcountKey#":' & _data.recordcount) />
			<cfif arguments.columnListFormat EQ "array">
				<cfset columnlist = "[" & ListQualify(columnlist, '"') & "]" />
				<cfset dJSONString.append(',"#columnlistKey#":' & columnlist) />
			<cfelse>
				<cfset dJSONString.append(',"#columnlistKey#":"' & columnlist & '"') />
			</cfif>
			<cfset dJSONString.append(',"#dataKey#":') />
			
			<!--- Make query a structure of arrays --->
			<cfif arguments.queryFormat EQ "query">
				<cfset dJSONString.append("{") />
				<cfset colPos = 1 />
				
				<cfloop list="#_data.columnlist#" index="column">
					<cfif colPos GT 1>
						<cfset dJSONString.append(",") />
					<cfelseif arguments.queryKeyCase EQ "lower">
						<cfset column = LCase(column) />
					</cfif>
					<cfset dJSONString.append('"' & column & '":[') />
					
					<cfloop query="data">
						<!--- Get cell value; recurse to get proper format depending on string/number/boolean data type --->
						<cfset tempVal = jsonencode( _data[column][_data.currentrow], arguments.queryFormat, arguments.queryKeyCase, arguments.stringNumbers, arguments.formatDates, arguments.columnListFormat ) />
						
						<cfif i GT 1>
							<cfset dJSONString.append(",") />
						</cfif>
						<cfset dJSONString.append(tempVal) />
					</cfloop>
					
					<cfset dJSONString.append("]") />
					
					<cfset colPos = colPos + 1 />
				</cfloop>
				<cfset dJSONString.append("}") />
			<!--- Make query an array of structures --->
			<cfelse>
				<cfset dJSONString.append("[") />
				<cfloop query="_data">
					<cfif i GT 1>
						<cfset dJSONString.append(",") />
					</cfif>
					<cfset dJSONString.append("{") />
					<cfset colPos = 1 />
					<cfloop list="#columnlist#" index="column">
						<cfset tempVal = jsonencode( _data[column][_data.currentrow], arguments.queryFormat, arguments.queryKeyCase, arguments.stringNumbers, arguments.formatDates, arguments.columnListFormat ) />
						
						<cfif colPos GT 1>
							<cfset dJSONString.append(",") />
						</cfif>
						
						<cfif arguments.queryKeyCase EQ "lower">
							<cfset column = LCase(column) />
						</cfif>
						<cfset dJSONString.append('"' & column & '":' & tempVal) />
						
						<cfset colPos = colPos + 1 />
					</cfloop>
					<cfset dJSONString.append("}") />
				</cfloop>
				<cfset dJSONString.append("]") />
			</cfif>
			
			<!--- Wrap all query data into an object --->
			<cfreturn "{" & dJSONString.toString() & "}" />
		
		<!--- UNKNOWN OBJECT TYPE --->
		<cfelse>
			<cfreturn '"' & "unknown-obj" & '"' />
		</cfif>
	</cffunction>

	<cffunction name="escapeFilterValue" access="public" output="false" returntype="string">
		<cfargument name="val" type="string" required="true" />

		<cfreturn replace(
			replace(
				replace(
					arguments.val, 
					"\", "\\", "ALL"
				),
				",", "\,", "ALL"
			),
			" />", "\;", "ALL"
		) />
	</cffunction>

</cfcomponent>