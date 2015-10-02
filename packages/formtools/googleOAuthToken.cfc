<cfcomponent displayname="Google OAuth Token" extends="farcry.core.packages.formtools.field" hint="Field component to liase with all string types"> 
	
	<cfproperty name="ftClientID" required="false" default="" options="" hint="The Google OAuth client ID - either a field name in the same type, or a config e.g. config.ga.clientID" />
	<cfproperty name="ftClientSecret" required="false" default="" hint="The Google OAuth client secret - either a field name in the same type, or a config e.g. config.ga.clientSecret" />
	<cfproperty name="ftScope" required="false" default="https://www.googleapis.com/auth/userinfo.profile" hint="A list of scopes being requested. General information and basic scopes can be found at https://developers.google.com/+/web/api/rest/oauth##login-scopes. A more complete list of scopes can be found at https://developers.google.com/oauthplayground/." />
	<cfproperty name="ftProxy" required="false" default="" hint="Either a field name in the same type or a config e.g. config.ga.proxy. Value found should be in the form [user:password@]domain[:port]." />
	<cfproperty name="ftSanityCheck" required="false" default="" hint="The name of a method in the same type. The result of this function is displayed under the authorisation link to provide the user with a check that authorisation worked." />


	<cffunction name="edit" access="public" output="true" returntype="string" hint="his will return a string of formatted HTML text to enable the user to edit the data">
		<cfargument name="typename" required="true" type="string" hint="The name of the type that this field is part of.">
		<cfargument name="stObject" required="true" type="struct" hint="The object of the record that this field is part of.">
		<cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
		<cfargument name="fieldname" required="true" type="string" hint="This is the name that will be used for the form field. It includes the prefix that will be used by ft:processform.">

		<cfset var html = "" />
		<cfset var sanity = "" />
		<cfset var keyClientID = "" />
		<cfset var key = "" />
		<cfset var accessConfig = {} />
		<cfset var redirectURL = "" />
		<cfset var oType = application.fapi.getContentType(arguments.typename) />
		<cfset var updateScript = "" />
		
		<!--- Fetch api config --->
		<cfset accessConfig = application.fc.lib.google.getAccessConfig(stObject=arguments.stObject, stMetadata=arguments.stMetadata) />
		<cfset redirectURL = getRedirectURL(argumentCollection=arguments) />

		<cfif len(arguments.stMetadata.value)>
			<cfset keyClientID = listfirst(arguments.stMetadata.value,":") />
			<cfset key = listrest(arguments.stMetadata.value,":") />

			<cfif len(arguments.stMetadata.ftSanityCheck) and structKeyExists(oType, arguments.stMetadata.ftSanityCheck)>
				<cfset accessConfig["refreshToken"] = key />

				<cfinvoke component="#oType#" method="#arguments.stMetadata.ftSanityCheck#" returnvariable="sanity">
					<cfinvokeargument name="typename" value="#arguments.typename#" />
					<cfinvokeargument name="accessConfig" value="#accessConfig#" />
				</cfinvoke>
			</cfif>
		</cfif>
		
		<cfsavecontent variable="html"><cfoutput>
			<cfif not len(accessConfig.clientID) or not len(accessConfig.clientSecret)>
				<input type='hidden' name='#arguments.fieldname#' id='#arguments.fieldname#' value='#arguments.stMetadata.value#' /> 
				<span id='#arguments.fieldname#-text'>Enter a Client ID and Client Secret</span>
			<cfelseif accessConfig.clientID neq keyClientID>
				<input type='hidden' name='#arguments.fieldname#' id='#arguments.fieldname#' value='' />
				<span id='#arguments.fieldname#-text'>The application Client ID has changed. [<a href='#redirectURL#&state=#urlencodedformat("#accessConfig.clientid#|#accessConfig.clientsecret#|#accessConfig.proxy#")#' target='_blank'>re-authorize the application</a> | <a href="##" onclick="updateRefreshToken('', ''); return false;">clear</a>]</span>
			<cfelseif len(arguments.stMetadata.value)>
				<input type='hidden' name='#arguments.fieldname#' id='#arguments.fieldname#' value='#arguments.stMetadata.value#' />
				<span id='#arguments.fieldname#-text'>You have provided authorization. [<a href='#redirectURL#&state=#urlencodedformat("#accessConfig.clientid#|#accessConfig.clientsecret#|#accessConfig.proxy#")#' target='_blank'>re-authorize</a> | <a href="##" onclick="updateRefreshToken('', ''); return false;">clear</a>]</span>
			<cfelse>
				<input type='hidden' name='#arguments.fieldname#' id='#arguments.fieldname#' value='#arguments.stMetadata.value#' />
				<span id='#arguments.fieldname#-text'>Please <a href='#redirectURL#&state=#urlencodedformat("#accessConfig.clientid#|#accessConfig.clientsecret#|#accessConfig.proxy#")#' target='_blank'>authorize</a> this application to access Google on your user's behalf.</span>
			</cfif>

			<div id='#arguments.fieldname#-sanitycheck'>#sanity#</div>
			<script type='text/javascript'>
				window.updateRefreshToken = function(key, sanitycheck){ 
					if (key.length){
						$j('###arguments.fieldname#').val('#accessConfig.clientID#:'+key);
						$j('###arguments.fieldname#-text').html('Authorization complete [<a href="#redirectURL#&state=#urlencodedformat("#accessConfig.clientid#|#accessConfig.clientsecret#|#accessConfig.proxy#")#" target="_blank">re-authorize</a> | <a href="##" onclick="updateRefreshToken(\'\', \'\'); return false;">clear</a>]'); 
					}
					else {
						$j('###arguments.fieldname#').val('');
						$j('###arguments.fieldname#-text').html("Please <a href='#redirectURL#&state=#urlencodedformat('#accessConfig.clientid#|#accessConfig.clientsecret#|#accessConfig.proxy#')#' target='_blank'>authorize</a> this application to access Google on your user's behalf."); 
					}
					$j('###arguments.fieldname#-sanitycheck').html(sanitycheck); 
				};
			</script>

			<p>NOTE: the <a href='https://console.developers.google.com/'>application</a> must support the <a href='#redirectURL#'>redirect URL</a>.</p>
		</cfoutput></cfsavecontent>

		<cfreturn html>
	</cffunction>

	<cffunction name="display" access="public" output="false" returntype="string" hint="This will return a string of formatted HTML text to display.">
		<cfargument name="typename" required="true" type="string" hint="The name of the type that this field is part of.">
		<cfargument name="stObject" required="true" type="struct" hint="The object of the record that this field is part of.">
		<cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
		<cfargument name="fieldname" required="true" type="string" hint="This is the name that will be used for the form field. It includes the prefix that will be used by ft:processform.">

		<cfset var html = "" />
		
		<cfsavecontent variable="html">
			<cfoutput>#arguments.stMetadata.value#</cfoutput>
		</cfsavecontent>
		
		<cfreturn html>
	</cffunction>

	<cffunction name="ajax" output="false" returntype="string" hint="Response to ajax requests for this formtool">
		<cfargument name="typename" required="true" type="string" hint="The name of the type that this field is part of.">
		<cfargument name="stObject" required="true" type="struct" hint="The object of the record that this field is part of.">
		<cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
		<cfargument name="fieldname" required="true" type="string" hint="This is the name that will be used for the form field. It includes the prefix that will be used by ft:processform.">

		<cfset var stMD = duplicate(arguments.stMetadata) />
		<cfset var oType = createobject("component",application.stCOAPI[arguments.typename].packagepath) />
		<cfset var FieldMethod = "" />
		<cfset var html = "" />

		<cfset stMD.ajaxrequest = "true" />
		
		<cfif structKeyExists(url, "googleendpoint")>
			<cfset html = getRedirectHTML(argumentCollection=arguments) />
		<cfelse>
			<cfif len(stMetadata.ftAjaxMethod)>
				<cfset FieldMethod = stMetadata.ftAjaxMethod />
				
				<!--- Check to see if this method exists in the current oType CFC. If not, use the formtool --->
				<cfif not structKeyExists(oType,stMetadata.ftAjaxMethod)>
					<cfset oType = this />
				</cfif>
			<cfelse>
				<cfif structKeyExists(oType,"ftEdit#url.property#")>
					<cfset FieldMethod = "ftEdit#url.property#">
				<cfelse>
					<cfset FieldMethod = "edit" />
					<cfset oType = application.formtools[url.formtool].oFactory />
				</cfif>
			</cfif>
			
			<cfinvoke component="#oType#" method="#FieldMethod#" returnvariable="html">
				<cfinvokeargument name="typename" value="#arguments.typename#" />
				<cfinvokeargument name="stObject" value="#arguments.stObject#" />
				<cfinvokeargument name="stMetadata" value="#stMD#" />
				<cfinvokeargument name="fieldname" value="#arguments.fieldname#" />
			</cfinvoke>
		</cfif>
		
		<cfreturn html />
	</cffunction>

	<cffunction name="getRedirectURL" access="public" output="false" returntype="string">
		<cfargument name="typename" required="true" type="string" hint="The name of the type that this field is part of.">
		<cfargument name="stObject" required="true" type="struct" hint="The object of the record that this field is part of.">
		<cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
		<cfargument name="fieldname" required="true" type="string" hint="This is the name that will be used for the form field. It includes the prefix that will be used by ft:processform.">

		<cfset var protocol = "http" />
		<cfset var domain = cgi.http_host />
		
		<cfreturn protocol & "://" & domain & "/webtop/facade/ftajax.cfm?formtool=googleOAuthToken&typename=#arguments.typename#&fieldname=&property=#arguments.stMetadata.name#&googleendpoint=1" />
	</cffunction>

	<cffunction name="getRedirectHTML" access="public" output="false" returntype="string">
		<cfargument name="typename" required="true" type="string" hint="The name of the type that this field is part of.">
		<cfargument name="stObject" required="true" type="struct" hint="The object of the record that this field is part of.">
		<cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
		<cfargument name="fieldname" required="true" type="string" hint="This is the name that will be used for the form field. It includes the prefix that will be used by ft:processform.">

		<cfset var html = "" />
		<cfset var redirectURL = getRedirectURL(argumentCollection=arguments) />
		<cfset var sanity = "" />
		<cfset var oType = "" />
		<cfset var accessConfig = {
			"clientID" = listgetat(url.state,1,"|"),
			"clientSecret" = listgetat(url.state,2,"|"),
			"proxy" = listlen(url.state,"|") eq 3 ? listgetat(url.state,3,"|") : ""
		} />
		
		<cfif isdefined("url.code")>
			<!--- Google has redirected back - get the refresh token and update the field --->
 			<cfset refreshToken = application.fc.lib.google.getRefreshToken(
 				authorizationCode = url.code, 
 				clientID = accessConfig.clientID, 
 				clientSecret = accessConfig.clientSecret, 
 				redirectURL = redirectURL, 
 				proxy = accessConfig.proxy
 			) />

 			<cfset oType = application.fapi.getContentType(arguments.typename) />
			<cfif len(arguments.stMetadata.ftSanityCheck) and structKeyExists(oType, arguments.stMetadata.ftSanityCheck)>
				<cfset accessConfig["refreshToken"] = refreshToken />
				<cfinvoke component="#oType#" method="#arguments.stMetadata.ftSanityCheck#" returnvariable="sanity">
					<cfinvokeargument name="typename" value="#arguments.typename#" />
					<cfinvokeargument name="accessConfig" value="#accessConfig#" />
				</cfinvoke>
			</cfif>
			
			<cfsavecontent variable="html"><cfoutput><script type="text/javascript">
				window.opener.updateRefreshToken('#refreshToken#',#serializeJSON(sanity)#);
				window.close();
			</script></cfoutput></cfsavecontent>
		<cfelse>
			<cflocation url="#application.fc.lib.google.getAuthorisationURL(clientID=accessConfig.clientid, redirectURL=redirectURL, scope=arguments.stMetadata.ftScope, state="#accessConfig.clientid#|#accessConfig.clientsecret#|#accessConfig.proxy#")#" addtoken="false" />
		</cfif>

		<cfreturn html />
	</cffunction>

</cfcomponent> 
