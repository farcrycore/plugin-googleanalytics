<cfcomponent displayname="Google Analytics configuration" hint="Configuration for Google Analytics" extends="farcry.core.packages.types.types" output="false" bObjectBroker="1">
	
	<cfproperty ftSeq="2" ftFieldset="Google Analytics Settings" name="bActive" type="boolean" default="1" hint="Urchin Code." ftLabel="Active" />
	<cfproperty ftSeq="3" ftFieldset="Google Analytics Settings" name="urchinCode" type="string" default="" hint="Urchin Code." ftLabel="Urchin Code" />
	<cfproperty ftSeq="4" ftFieldset="Google Analytics Settings" name="types" type="longchar" required="true" default="dmFile" ftLabel="Types" />
	<cfproperty ftSeq="5" ftFieldset="Google Analytics Settings" name="lDomains" type="longchar" default="" hint="Urchin Code." ftLabel="Domain(s)" ftHint="<strong>Optional:</strong> Leave empty to track all domains or define each domain on a new line." bLabel="true" />
	<cfproperty ftSeq="6" ftFieldset="Google Analytics Settings" name="urlWhiteList" type="string" default="q" ftDefault="q" ftLabel="URL Variable Whitelist" ftHint="These URL variables will always be included in tracked URLs" />
	<cfproperty ftSeq="7" ftFieldset="Google Analytics Settings" name="bDemographics" type="boolean" default="0" ftLabel="Enable Demographics reports" ftHint="Enable Demographics and Interests reports, please update your privacy policy to adhere to <a href='https://support.google.com/analytics/answer/2700409'>Google's Policy requirements for Display Advertising</a>."/>

	<cfproperty ftSeq="20" ftFieldset="Google Analytics API Access" name="googleProxy" type="string" ftLabel="Proxy" ftHint="If internet access is only available through a proxy, set here. Use the format '[username:password@]domain[:port]'." ftHelpSection="You will need to set up <a href='https://code.google.com/apis/console'>API access</a> to use this functionality. The redirect URL this plugin uses is http://your.domain.com/webtop/admin/customadmin.cfm?plugin=googleanalytics&module=gapi_oauth.cfm" />
	<cfproperty ftSeq="21" ftFieldset="Google Analytics API Access" name="googleClientID" type="string" ftLabel="Client ID" ftHint="This should be copied exactly from the <a href='https://code.google.com/apis/console'>API Console</a>." />
	<cfproperty ftSeq="22" ftFieldset="Google Analytics API Access" name="googleClientSecret" type="string" ftLabel="Client Secret" ftHint="This should be copied exactly from the <a href='https://code.google.com/apis/console'>API Console</a>." />
	<cfproperty ftSeq="23" ftFieldset="Google Analytics API Access" name="googleRefreshToken" type="string" ftLabel="Refresh Token" ftWatch="googleClientID,googleClientSecret,googleProxy" ftHint="This is obtained from Google after you authorize FarCry for access to Google Analytics, and is used for ongoing API access." />
	<cfproperty ftSeq="24" ftFieldset="Google Analytics API Access" name="googleAccountID" type="string" ftLabel="Account" ftType="list" ftWatch="googleRefreshToken" />
	<cfproperty ftSeq="25" ftFieldset="Google Analytics API Access" name="googleWebPropertyID" type="string" ftLabel="Web Property" ftType="list" ftWatch="googleAccountID" />
	<cfproperty ftSeq="26" ftFieldset="Google Analytics API Access" name="googleProfileID" type="string" ftLabel="Profile" ftType="list" ftWatch="googleWebPropertyID" />
	
	<cfproperty ftSeq="31" ftFieldset="Statistics Caching" name="cacheDays" type="integer" ftLabel="Days" ftHint="How many days back to consider" ftSectionHelp="Stastistics can be cached for use in 'Most Popular Article' type functionaliry." default="7" ftDefault="7" />
	
	
	<cffunction name="ftEditGoogleRefreshToken" access="public" output="false" returntype="string" hint="his will return a string of formatted HTML text to enable the user to edit the data">
		<cfargument name="typename" required="true" type="string" hint="The name of the type that this field is part of.">
		<cfargument name="stObject" required="true" type="struct" hint="The object of the record that this field is part of.">
		<cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
		<cfargument name="fieldname" required="true" type="string" hint="This is the name that will be used for the form field. It includes the prefix that will be used by ft:processform.">
		
		<cfset var keyClientID = "" />
		<cfset var key = "" />
		
		<cfif len(arguments.stMetadata.value)>
			<cfset keyClientID = listfirst(arguments.stMetadata.value,":") />
			<cfset key = listrest(arguments.stMetadata.value,":") />
		</cfif>
		
		<!--- If the user has changed the clientID then recommend reauthorisation --->
		<cfif len(arguments.stObject.googleClientID) and len(arguments.stObject.googleClientSecret) and arguments.stObject.googleClientID neq keyClientID>
			<cfreturn "<script type='text/javascript'>window.updateRefreshToken = function(key){ $j('###arguments.fieldname#').val('#arguments.stObject.googleClientID#:'+key);$j('###arguments.fieldname#-text').html('#arguments.stObject.googleClientID# has been authorized'); };</script><input type='hidden' name='#arguments.fieldname#' id='#arguments.fieldname#' value='' /><span id='#arguments.fieldname#-text'>You have changed the Client ID. You will need to <a href='#application.url.webtop#/admin/customadmin.cfm?plugin=googleAnalytics&module=gapi_oauth.cfm&clientid=#arguments.stObject.googleClientID#&clientsecret=#arguments.stObject.googleClientSecret#&proxy=#urlencodedformat(arguments.stObject.googleProxy)#' target='_blank'>authorize it</a> before saving.</span>" />
		</cfif>
		
		<cfif len(arguments.stMetadata.value)>
			<cfreturn "<script type='text/javascript'>window.updateRefreshToken = function(key){ $j('###arguments.fieldname#').val('#arguments.stObject.googleClientID#:'+key);$j('###arguments.fieldname#-text').html('#arguments.stObject.googleClientID# has been authorized'); };</script><input type='hidden' name='#arguments.fieldname#' id='#arguments.fieldname#' value='#arguments.stMetadata.value#' /><span id='#arguments.fieldname#-text'>#keyClientID# has been authorized. You can <a href='#application.url.webtop#/admin/customadmin.cfm?plugin=googleAnalytics&module=gapi_oauth.cfm&clientid=#arguments.stObject.googleClientID#&clientsecret=#arguments.stObject.googleClientSecret#&proxy=#urlencodedformat(arguments.stObject.googleProxy)#' target='_blank'>re-authorize</a> as another user if necessary.</span>" />
		</cfif>
		
		<cfreturn "<input type='hidden' name='#arguments.fieldname#' id='#arguments.fieldname#' value='#arguments.stMetadata.value#' /> Enter a Client ID and Client Secret" />
	</cffunction>
	
	<cffunction name="ftEditGoogleAccountID" access="public" output="false" returntype="string" hint="his will return a string of formatted HTML text to enable the user to edit the data">
		<cfargument name="typename" required="true" type="string" hint="The name of the type that this field is part of.">
		<cfargument name="stObject" required="true" type="struct" hint="The object of the record that this field is part of.">
		<cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
		<cfargument name="fieldname" required="true" type="string" hint="This is the name that will be used for the form field. It includes the prefix that will be used by ft:processform.">
		
		<cfset var html = "" />
		<cfset var thisfield = "" />
		<cfset var qAccounts = "" />
		<cfset var accessToken = "" />
		
		<cfif not len(arguments.stObject.googleRefreshToken)>
			<cfreturn "<input name='#arguments.fieldname#' id='#arguments.fieldname#' value='#arguments.stMetadata.value#' /> Enter and authorize your Client ID and Client Secret" />
		</cfif>
		
		<cftry>
			<cfset accessToken = application.fc.lib.ga.getAccessToken(listrest(arguments.stObject.googleRefreshToken,":"),arguments.stObject.googleClientID,arguments.stObject.googleClientSecret,arguments.stObject.googleProxy) />
			<cfset qAccounts = application.fc.lib.ga.getAccounts(accessToken,arguments.stObject.googleProxy) />
			
			<cfcatch>
				<cfreturn html & " #cfcatch.message#" />
			</cfcatch>
		</cftry>
		
		<cfsavecontent variable="html"><cfoutput>
			<cfif qAccounts.RecordCount >
				<select name="#arguments.fieldname#" id="#arguments.fieldname#">
					<option value="">-- select account --</option>
					<cfloop query="qAccounts">
						<option value="#qAccounts.id#"<cfif qAccounts.id eq arguments.stMetadata.value> selected</cfif>>#qAccounts.name#</option>
					</cfloop>
				</select>
			<cfelse>
				<span>No authorized account found. Please check your Google API Account rights.</span>
			</cfif>
		</cfoutput></cfsavecontent>
		
		<cfreturn html />
	</cffunction>
	
	<cffunction name="ftEditGoogleWebPropertyID" access="public" output="false" returntype="string" hint="his will return a string of formatted HTML text to enable the user to edit the data">
		<cfargument name="typename" required="true" type="string" hint="The name of the type that this field is part of.">
		<cfargument name="stObject" required="true" type="struct" hint="The object of the record that this field is part of.">
		<cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
		<cfargument name="fieldname" required="true" type="string" hint="This is the name that will be used for the form field. It includes the prefix that will be used by ft:processform.">
		
		<cfset var html = "" />
		<cfset var thisfield = "" />
		<cfset var qWebProperties = "" />
		<cfset var accessToken = "" />
		
		<cfif not len(arguments.stObject.googleAccountID)>
			<cfreturn "<input name='#arguments.fieldname#' id='#arguments.fieldname#' value='#arguments.stMetadata.value#' /> Enter and authorize your Client ID and Client Secret" />
		</cfif>
		
		<cftry>
			<cfset accessToken = application.fc.lib.ga.getAccessToken(listrest(arguments.stObject.googleRefreshToken,":"),arguments.stObject.googleClientID,arguments.stObject.googleClientSecret,arguments.stObject.googleProxy) />
			<cfset qWebProperties = application.fc.lib.ga.getWebProperties(arguments.stObject.googleAccountID,accessToken,arguments.stObject.googleProxy) />
			
			<cfcatch>
				<cfreturn html & " #cfcatch.message#" />
			</cfcatch>
		</cftry>
		
		<cfsavecontent variable="html"><cfoutput>
			<select name="#arguments.fieldname#" id="#arguments.fieldname#">
				<option value="">-- select account --</option>
				<cfloop query="qWebProperties">
					<option value="#qWebProperties.id#"<cfif qWebProperties.id eq arguments.stMetadata.value> selected</cfif>>#qWebProperties.name#</option>
				</cfloop>
			</select>
		</cfoutput></cfsavecontent>
		
		<cfreturn html />
	</cffunction>
	
	<cffunction name="ftEditGoogleProfileID" access="public" output="false" returntype="string" hint="his will return a string of formatted HTML text to enable the user to edit the data">
		<cfargument name="typename" required="true" type="string" hint="The name of the type that this field is part of.">
		<cfargument name="stObject" required="true" type="struct" hint="The object of the record that this field is part of.">
		<cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
		<cfargument name="fieldname" required="true" type="string" hint="This is the name that will be used for the form field. It includes the prefix that will be used by ft:processform.">
		
		<cfset var html = "" />
		<cfset var thisfield = "" />
		<cfset var qProfiles = "" />
		<cfset var accessToken = "" />
		
		<cfif not len(arguments.stObject.googleWebPropertyID)>
			<cfreturn "<input name='#arguments.fieldname#' id='#arguments.fieldname#' value='#arguments.stMetadata.value#' /> Enter and authorize your Client ID and Client Secret" />
		</cfif>
		
		<cftry>
			<cfset accessToken = application.fc.lib.ga.getAccessToken(listrest(arguments.stObject.googleRefreshToken,":"),arguments.stObject.googleClientID,arguments.stObject.googleClientSecret,arguments.stObject.googleProxy) />
			<cfset qProfiles = application.fc.lib.ga.getProfiles(arguments.stObject.googleAccountID,arguments.stObject.googleWebPropertyID,accessToken,arguments.stObject.googleProxy) />
			
			<cfcatch>
				<cfreturn html & " #cfcatch.message#" />
			</cfcatch>
		</cftry>
		
		<cfsavecontent variable="html"><cfoutput>
			<select name="#arguments.fieldname#" id="#arguments.fieldname#">
				<option value="">-- select account --</option>
				<cfloop query="qProfiles">
					<option value="#qProfiles.id#"<cfif qProfiles.id eq arguments.stMetadata.value> selected</cfif>>#qProfiles.name#</option>
				</cfloop>
			</select>
		</cfoutput></cfsavecontent>
		
		<cfreturn html />
	</cffunction>
	
	
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
				<cfquery datasource="#application.dsn#" name="qSites" cachedwithin="#createTimeSpan(0,0,1,0)#">
					SELECT objectID
					FROM gaSetting
					WHERE bActive = 1 AND (lDomains is null or lDomains like '')
				</cfquery>
				<cfif qSites.recordCount>
					<cfset stSetting = getData(qSites.objectID) />						
				</cfif>
				
			</cfif>
			
			<cfcatch></cfcatch>
		</cftry>
	
		<cfreturn stSetting />
	</cffunction>
	
</cfcomponent>