component {
	
	public any function init(){
		this.access_tokens = {};

		return this;
	}

	public struct function getAccessConfig(required struct stObject, required struct stMetadata){
		var accessConfig = {};

		// client id
		if (refindnocase("^config\.", arguments.stMetadata.ftClientID)){
			accessConfig["clientID"] = application.fapi.getConfig(listGetAt(arguments.stMetadata.ftClientID, 2, "."), listGetAt(arguments.stMetadata.ftClientID, 3, "."))
		}
		else {
			accessConfig["clientID"] = arguments.stObject[arguments.stMetadata.ftClientID];
		}

		// client secret
		if (refindnocase("^config\.", arguments.stMetadata.ftClientSecret)){
			accessConfig["clientSecret"] = application.fapi.getConfig(listGetAt(arguments.stMetadata.ftClientSecret, 2, "."), listGetAt(arguments.stMetadata.ftClientSecret, 3, "."))
		}
		else {
			accessConfig["clientSecret"] = arguments.stObject[arguments.stMetadata.ftClientSecret];
		}

		// proxy
		if (len(arguments.stMetadata.ftProxy)){
			if (refindnocase("^config\.", arguments.stMetadata.ftProxy)){
				accessConfig["proxy"] = application.fapi.getConfig(listGetAt(arguments.stMetadata.ftProxy, 2, "."), listGetAt(arguments.stMetadata.ftProxy, 3, "."))
			}
			else {
				accessConfig["proxy"] = arguments.stObject[arguments.stMetadata.ftProxy];
			}
		}
		else {
			accessConfig["proxy"] = "";
		}

		// refresh token
		accessConfig["refreshToken"] = listrest(arguments.stObject[arguments.stMetadata.name], ":");

		return accessConfig;
	}

	public struct function parseProxy(required string proxy){
		var stResult = {
			"user" = "",
			"password" = "",
			"domain" = "",
			"port" = "80"
		};
		
		if (len(arguments.proxy)){
			if (listlen(arguments.proxy,"@") eq 2){
				stResult["login"] = listfirst(arguments.proxy,"@");
				stResult["user"] = listfirst(stResult.login,":");
				stResult["password"] = listlast(stResult.login,":");
			}
			else {
				stResult["user"] = "";
				stResult["password"] = "";
			}

			stResult["server"] = listlast(arguments.proxy,"@");
			stResult["domain"] = listfirst(stResult.server,":");

			if (listlen(stResult["server"],":") eq 2){
				stResult["port"] = listlast(stResult.server,":");
			}
			else {
				stResult["port"] = "80";
			}
		}
		
		return stResult;
	}

	/*
		From http://code.google.com/apis/analytics/docs/gdata/v3/gdataAuthorization.html: 
	    1) When you create your application, you register it with Google. Google then provides information you'll need later, such as a client ID and a client secret.
	    2) Activate the Google Analytics API in the Services pane of the Google APIs Console. (If it isn't listed in the Console, then skip this step.)
	    3) When your application needs access to user data, it asks Google for a particular scope of access. ***
	    4) Google displays an OAuth dialog to the user, asking them to authorize your application to request some of their data.
	    5) If the user approves, then Google gives your application a short-lived access token.
	    6) Your application requests user data, attaching the access token to the request.
	    7) If Google determines that your request and the token are valid, it returns the requested data.
	 */
	public string function getAuthorisationURL(required string clientID, required string redirectURL, string accessType="offline", string scope="https://www.googleapis.com/auth/userinfo.profile", string state=""){
		var authURL = "https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=#arguments.clientid#&redirect_uri=#urlencodedformat(arguments.redirectURL)#&scope=#arguments.scope#&access_type=#arguments.accesstype#&state=#urlencodedformat(arguments.state)#&approval_prompt=force";

		return authURL;
	}
	
	public string function getRefreshToken(required string authorizationCode, required string clientID, required string clientSecret, required string redirectURL, required string proxy){
		var cfhttp = {};
		var stResult = {};
		var stProxy = parseProxy(arguments.proxy);
		var stDetail = "";
		
		http url="https://accounts.google.com/o/oauth2/token" method="POST" proxyServer="#stProxy.domain#" proxyPort="#stProxy.port#" proxyUser="#stProxy.user#" proxyPassword="#stProxy.password#"{
			httpparam type="formfield" name="code" value="#arguments.authorizationCode#";
			httpparam type="formfield" name="client_id" value="#arguments.clientID#";
			httpparam type="formfield" name="client_secret" value="#arguments.clientSecret#";
			httpparam type="formfield" name="redirect_uri" value="#arguments.redirectURL#";
			httpparam type="formfield" name="grant_type" value="authorization_code";
		}
		
		if (not cfhttp.statuscode eq "200 OK"){
			if (listfindnocase("vagrant,dev,uat", application.stack)){
				stDetail = serializeJSON({ "arguments" : duplicate(arguments) });
			}
			throw(message="Error retrieving refresh token: #cfhttp.statuscode# (#cfhttp.filecontent#)", detail=stDetail);
		}
		
		stResult = deserializeJSON(cfhttp.FileContent.toString());
		
		this.access_token = stResult.access_token;
		this.access_token_expires = dateadd("s",stResult.expires_in,now());
		
		return stResult.refresh_token;
	}
	
	public string function getAccessToken(required string refreshToken, required string clientID, required string clientSecret, required string proxy){
		var cfhttp = {};
		var stResult = {};
		var stProxy = parseProxy(arguments.proxy);
		
		if (not structkeyexists(this.access_tokens, arguments.refreshToken) or datecompare(this.access_tokens[arguments.refreshToken].expires,now()) lt 0){
			http url="https://accounts.google.com/o/oauth2/token" method="POST" proxyServer="#stProxy.domain#" proxyPort="#stProxy.port#" proxyUser="#stProxy.user#" proxyPassword="#stProxy.password#"{
				httpparam type="formfield" name="refresh_token" value="#arguments.refreshToken#";
				httpparam type="formfield" name="client_id" value="#arguments.clientID#";
				httpparam type="formfield" name="client_secret" value="#arguments.clientSecret#";
				httpparam type="formfield" name="grant_type" value="refresh_token";
			}
			
			if (not cfhttp.statuscode eq "200 OK"){
				throw(message="Error accessing Google API: #cfhttp.statuscode#");
			}
			
			stResult = deserializeJSON(cfhttp.FileContent.toString());
			
			this.access_tokens[arguments.refreshToken] = {
				"token" = stResult.access_token,
				"expires" = dateadd("s",stResult.expires_in,now())
			};
		}
		
		return this.access_tokens[arguments.refreshToken].token;
	}

	public any function makeRequest(required struct accessConfig, required string resource, string method="", struct stQuery={}, struct stData={}, string format="json"){
		var stProxy = parseProxy(arguments.accessConfig.proxy);
		var accessToken = getAccessToken(argumentCollection=arguments.accessConfig);
		var result = "";
		var item = "";
		var resourceURL = arguments.resource;

		for (item in listToArray(structKeyList(arguments.stQuery))){
			if (find("?", resourceURL)){
				resourceURL = resourceURL & "&";
			}
			else {
				resourceURL = resourceURL & "?";
			}

			resourceURL = resourceURL & URLEncodedFormat(item) & "=" & URLEncodedFormat(arguments.stQuery[item]);
		}

		if (arguments.method eq ""){
			if (structisempty(arguments.stData)){
				arguments.method = "GET";
			}
			else {
				arguments.method = "POST";
			}
		}

		http method="#arguments.method#" url="https://www.googleapis.com#resourceURL#" proxyServer="#stProxy.domain#" proxyPort="#stProxy.port#" proxyUser="#stProxy.user#" proxyPassword="#stProxy.password#"{
			httpparam type="header" name="Authorization" value="Bearer #accessToken#";

			if (not structisempty(arguments.stData)){
				httpparam type="header" name="Content-Type" value="application/json";
				httpparam type="body" value="#serializeJSON(arguments.stData)#";
			}
		}
		
		if (not refindnocase("^20. ",cfhttp.statuscode)){
			throw(message="Error accessing Google API: #cfhttp.statuscode#", detail=serializeJSON({ 
				"resource" = arguments.resource,
				"method" = arguments.method,
				"query_string" = arguments.stQuery,
				"body" = arguments.stData,
				"resourceURL" = resourceURL,
				"response" = isjson(cfhttp.filecontent.toString()) ? deserializeJSON(cfhttp.filecontent.toString()) : cfhttp.filecontent.toString()
			}));
		}
		
		result = cfhttp.filecontent.toString();

		if (len(result)){
			switch (arguments.format){
				case "json":
					result = deserializeJSON(result);
					break;
			}
		}
		else {
			result = {};
		}

		return result;
	}

	public query function itemsToQuery(required array items, string order){
		var q = "";
		var item = {};
		var columnNames = [];
		var columnTypes = [];
		var col = "";
		var queryService = "";

		for (item in arguments.items){
			if (not isQuery(q)){
				for (col in listToArray(structKeyList(item))){
					if (isSimpleValue(item[col])){
						arrayAppend(columnNames,col);
						switch (col){
							case "created": case "updated":
								arrayAppend(columnTypes,"date");
								break;
							default:
								arrayAppend(columnTypes,"varchar");
						}
					}
				}
				q = querynew(columnNames, columnTypes);
			}

			queryAddRow(q);
			for (col in columnNames){
				if (structKeyExists(item,col)){
					querySetCell(q,col,item[col]);
				}
			}
		}

		if (structKeyExists(arguments,"order") and len(arguments.order)){
			queryService = new query();
			queryService.setName("myQuery");
			queryService.setDBType("query");
			queryService.setAttributes(sourceQuery=q);
			objQueryResult = local.queryService.execute(sql="SELECT * FROM sourceQuery ORDER BY #arguments.order#");
			q = objQueryResult.getResult();
		}

		return q;
	}

	/*
	 Serialize native ColdFusion objects into a JSON formated string.
	 
	 @param arg 	 The data to encode. (Required)
	 @return Returns a string. 
	 @author Jehiah Czebotar (jehiah@gmail.com) 
	 @version 2, June 27, 2008 
	*/
	public string function jsonencode(required any data, string queryFormat="query", string queryKeyCase="lower", boolean stringNumbers=false, boolean formatDates=false, string columnListFormat="string"){
		// VARIABLE DECLARATION
		var jsonString = "";
		var tempVal = "";
		var arKeys = "";
		var colPos = 1;
		var i = 1;
		var column = "";
		var datakey = "";
		var recordcountkey = "";
		var columnlist = "";
		var columnlistkey = "";
		var dJSONString = "";
		var escapeToVals = "\\,\"",\/,\b,\t,\n,\f,\r";
		var escapeVals = "\,"",/,#Chr(8)#,#Chr(9)#,#Chr(10)#,#Chr(12)#,#Chr(13)#";
		
		var _data = arguments.data;

		// BOOLEAN
		if (IsBoolean(_data) AND NOT IsNumeric(_data) AND NOT ListFindNoCase("Yes,No", _data)){
			return LCase(ToString(_data));
		}
		
		// NUMBER
		else if (NOT stringNumbers AND IsNumeric(_data) AND NOT REFind("^0+[^\.]",_data)){
			return ToString(_data);
		}
		
		// DATE
		else if (IsDate(_data) AND arguments.formatDates){
			return '"#DateFormat(_data, "medium")# #TimeFormat(_data, "medium")#"';
		}
		
		// STRING
		else if (IsSimpleValue(_data)){
			return '"' & ReplaceList(_data, escapeVals, escapeToVals) & '"';
		}
		
		// ARRAY
		else if (IsArray(_data)){
			dJSONString = createObject('java','java.lang.StringBuffer').init("");
			for (i=1; i<=ArrayLen(_data); i++){
				tempVal = jsonencode( _data[i], arguments.queryFormat, arguments.queryKeyCase, arguments.stringNumbers, arguments.formatDates, arguments.columnListFormat );
				if (dJSONString.toString() EQ ""){
					dJSONString.append(tempVal);
				}
				else {
					dJSONString.append("," & tempVal);
				}
			}
			
			return "[" & dJSONString.toString() & "]";
		}
		
		// STRUCT
		else if (IsStruct(_data)){
			dJSONString = createObject('java','java.lang.StringBuffer').init("");
			arKeys = StructKeyArray(_data);
			for (i=1; i<=ArrayLen(arKeys); i++){
				tempVal = jsonencode( _data[ arKeys[i] ], arguments.queryFormat, arguments.queryKeyCase, arguments.stringNumbers, arguments.formatDates, arguments.columnListFormat );
				if (dJSONString.toString() EQ ""){
					dJSONString.append('"' & arKeys[i] & '":' & tempVal);
				}
				else {
					dJSONString.append("," & '"' & arKeys[i] & '":' & tempVal);
				}
			}
			
			return "{" & dJSONString.toString() & "}";
		}
		
		// QUERY
		else if (IsQuery(_data)){
			dJSONString = createObject('java','java.lang.StringBuffer').init("");
			
			// Add query meta data
			if (arguments.queryKeyCase EQ "lower"){
				recordcountKey = "recordcount";
				columnlistKey = "columnlist";
				columnlist = LCase(_data.columnlist);
				dataKey = "data";
			}
			else {
				recordcountKey = "RECORDCOUNT";
				columnlistKey = "COLUMNLIST";
				columnlist = _data.columnlist;
				dataKey = "data";
			}
			
			dJSONString.append('"#recordcountKey#":' & _data.recordcount);
			if (arguments.columnListFormat EQ "array"){
				columnlist = "[" & ListQualify(columnlist, '"') & "]";
				dJSONString.append(',"#columnlistKey#":' & columnlist);
			}
			else {
				dJSONString.append(',"#columnlistKey#":"' & columnlist & '"');
			}
			dJSONString.append(',"#dataKey#":');
			
			// Make query a structure of arrays
			if (arguments.queryFormat EQ "query"){
				dJSONString.append("{");
				colPos = 1;
				
				for (column in listToArray(_data.columnlist)){
					if (colPos GT 1){
						dJSONString.append(",");
					}
					if (arguments.queryKeyCase EQ "lower"){
						column = LCase(column);
					}
					dJSONString.append('"' & column & '":[');
					
					for (i=1; i<=_data.recordcount; i++){
						// Get cell value; recurse to get proper format depending on string/number/boolean data type
						tempVal = jsonencode( _data[column][i], arguments.queryFormat, arguments.queryKeyCase, arguments.stringNumbers, arguments.formatDates, arguments.columnListFormat );
						
						if (i GT 1){
							dJSONString.append(",");
						}
						dJSONString.append(tempVal);
					}
					
					dJSONString.append("]");
					
					colPos = colPos + 1;
				}
				dJSONString.append("}");
			// Make query an array of structures
			}
			else {
				dJSONString.append("[");
				for (i=1; i<=_data.recordcount; i++){
					if (i GT 1){
						dJSONString.append(",");
					}
					dJSONString.append("{");
					colPos = 1;
					for (column in listtoarray(columnlist)){
						tempVal = jsonencode( _data[column][i], arguments.queryFormat, arguments.queryKeyCase, arguments.stringNumbers, arguments.formatDates, arguments.columnListFormat );
						
						if (colPos GT 1){
							dJSONString.append(",");
						}
						
						if (arguments.queryKeyCase EQ "lower"){
							column = LCase(column);
						}
						dJSONString.append('"' & column & '":' & tempVal);
						
						colPos = colPos + 1;
					}
					dJSONString.append("}");
				}
				dJSONString.append("]");
			}
			
			// Wrap all query data into an object
			return "{" & dJSONString.toString() & "}";
		}
		
		// UNKNOWN OBJECT TYPE
		else {
			return '"' & "unknown-obj" & '"';
		}
	}

	public string function escapeFilterValue(required string val){
		return replace(
			replace(
				replace(
					arguments.val, 
					"\", "\\", "ALL"
				),
				",", "\,", "ALL"
			),
			";", "\;", "ALL"
		);
	}

}