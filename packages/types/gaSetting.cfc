<cfcomponent displayname="Google Analytics configuration" hint="Configuration for Google Analytics" extends="farcry.core.packages.types.types" output="false" bObjectBroker="1">

	<cfproperty name="bActive" type="boolean" default="1" 
		ftSeq="1" ftFieldset="Google Analytics Settings" ftLabel="Active"
		hint="Urchin Code.">

	<cfproperty name="urchinCode" type="string" default="" 
		ftSeq="2" ftFieldset="Google Analytics Settings" ftLabel="Urchin Code"
		hint="Urchin Code.">

	<cfproperty name="types" type="longchar" required="true" default="dmFile" 
		ftSeq="3" ftFieldset="Google Analytics Settings" ftLabel="Types">

	<cfproperty name="lDomains" type="longchar" default="" 
		ftSeq="4" ftFieldset="Google Analytics Settings" ftLabel="Domain(s)" 
		bLabel="true"
		ftHint="<strong>Optional:</strong> Leave empty to track all domains or define each domain on a new line."
		hint="Urchin Code.">

	<cfproperty name="urlWhiteList" type="string" default="q" 
		ftSeq="5" ftFieldset="Google Analytics Settings" ftLabel="URL Variable Whitelist" 
		ftDefault="q"
		ftHint="These URL variables will always be included in tracked URLs">

	<cfproperty name="bDemographics" type="boolean" default="0" 
		ftSeq="6" ftFieldset="Google Analytics Settings" ftLabel="Enable Demographics reports"
		ftHint="Enable Demographics and Interests reports, please update your privacy policy to adhere to <a href='https://support.google.com/analytics/answer/2700409'>Google's Policy requirements for Display Advertising</a>.">


	<cfproperty name="googleProxy" type="string" 
		ftSeq="7" ftFieldset="Google Analytics API Access" ftLabel="Proxy" 
		ftHelpSection="You will need to set up <a href='https://code.google.com/apis/console'>API access</a> to use this functionality. The redirect URL this plugin uses is http://your.domain.com/webtop/admin/customadmin.cfm?plugin=googleanalytics&module=gapi_oauth.cfm"
		ftHint="If internet access is only available through a proxy, set here. Use the format '[username:password@]domain[:port]'.">

	<cfproperty name="googleClientID" type="string" 
		ftSeq="8" ftFieldset="Google Analytics API Access" ftLabel="Client ID"
		ftHint="This should be copied exactly from the <a href='https://code.google.com/apis/console'>API Console</a>.">

	<cfproperty name="googleClientSecret" type="string" 
		ftSeq="9" ftFieldset="Google Analytics API Access" ftLabel="Client Secret"
		ftHint="This should be copied exactly from the <a href='https://code.google.com/apis/console'>API Console</a>.">

	<cfproperty name="googleRefreshToken" type="string" 
		ftSeq="10" ftFieldset="Google Analytics API Access" ftLabel="Refresh Token" 
		ftType="googleOAuthToken"
		ftProxy="googleProxy" ftClientID="googleClientID" ftClientSecret="googleClientSecret" ftScope="https://www.googleapis.com/auth/analytics.readonly"
		ftWatch="googleProxy,googleClientID,googleClientSecret"
		ftHint="This is obtained from Google after you authorize FarCry for access to Google Analytics, and is used for ongoing API access.">

	<cfproperty name="googleAccountID" type="string" 
		ftSeq="11" ftFieldset="Google Analytics API Access" ftLabel="Account" 
		ftType="list" 
		ftWatch="googleRefreshToken">

	<cfproperty name="googleWebPropertyID" type="string" 
		ftSeq="12" ftFieldset="Google Analytics API Access" ftLabel="Web Property" 
		ftType="list" 
		ftWatch="googleAccountID">

	<cfproperty name="googleProfileID" type="string" 
		ftSeq="13" ftFieldset="Google Analytics API Access" ftLabel="Profile" 
		ftType="list" 
		ftWatch="googleWebPropertyID">

	<cfproperty name="cacheDays" type="integer" default="7" 
		ftSeq="14" ftFieldset="Statistics Caching" ftLabel="Days" 
		ftDefault="7" 
		ftSectionHelp="Stastistics can be cached for use in 'Most Popular Article' type functionaliry."
		ftHint="How many days back to consider">


	<cffunction name="ftEditGoogleAccountID" access="public" output="false" returntype="string" hint="his will return a string of formatted HTML text to enable the user to edit the data">
		<cfargument name="typename" required="true" type="string" hint="The name of the type that this field is part of.">
		<cfargument name="stObject" required="true" type="struct" hint="The object of the record that this field is part of.">
		<cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
		<cfargument name="fieldname" required="true" type="string" hint="This is the name that will be used for the form field. It includes the prefix that will be used by ft:processform.">
		
		<cfset var html = "" />
		<cfset var thisfield = "" />
		<cfset var qAccounts = "" />
		<cfset var accessConfig = "" />
		
		<cfif not len(arguments.stObject.googleRefreshToken)>
			<cfreturn "<input name='#arguments.fieldname#' id='#arguments.fieldname#' value='#arguments.stMetadata.value#' /> Enter and authorize your Client ID and Client Secret" />
		</cfif>
		
		<cftry>
			<cfset accessConfig = application.fc.lib.google.getAccessConfig(stObject=arguments.stObject, stMetadata=application.fapi.getPropertyMetadata("gaSetting", "googleRefreshToken")) />
			<cfset qAccounts = application.fc.lib.ga.getAccounts(accessConfig=accessConfig) />
			
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
		<cfset var accessConfig = "" />
		
		<cfif not len(arguments.stObject.googleAccountID)>
			<cfreturn "<input name='#arguments.fieldname#' id='#arguments.fieldname#' value='#arguments.stMetadata.value#' /> Enter and authorize your Client ID and Client Secret" />
		</cfif>
		
		<cftry>
			<cfset accessConfig = application.fc.lib.google.getAccessConfig(stObject=arguments.stObject, stMetadata=application.fapi.getPropertyMetadata("gaSetting", "googleRefreshToken")) />
			<cfset qWebProperties = application.fc.lib.ga.getWebProperties(accountID=arguments.stObject.googleAccountID, accessConfig=accessConfig) />
			
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
		<cfset var accessConfig = "" />
		
		<cfif not len(arguments.stObject.googleWebPropertyID)>
			<cfreturn "<input name='#arguments.fieldname#' id='#arguments.fieldname#' value='#arguments.stMetadata.value#' /> Enter and authorize your Client ID and Client Secret" />
		</cfif>
		
		<cftry>
			<cfset accessConfig = application.fc.lib.google.getAccessConfig(stObject=arguments.stObject, stMetadata=application.fapi.getPropertyMetadata("gaSetting", "googleRefreshToken")) />
			<cfset qProfiles = application.fc.lib.ga.getProfiles(accountID=arguments.stObject.googleAccountID, webPropertyID=arguments.stObject.googleWebPropertyID, accessConfig=accessConfig) />
			
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

	<cffunction name="afterSave" access="public" output="false" returntype="struct">
		<cfargument name="stProperties" type="struct" />

		<cfset var hostname = "" />

		<cfloop collection="#application.stPlugins.googleanalytics#" item="hostname">
			<cfif find(".", hostname)>
				<cfset structDelete(application.stPlugins.googleanalytics, hostname) />
			</cfif>
		</cfloop>

		<cfreturn arguments.stProperties />
	</cffunction>
	
	<cffunction name="autoSetLabel" access="public" output="false" returntype="string" hint="Automagically sets the label">
		<cfargument name="stProperties" required="true" type="struct">

		<cfif structKeyExists(arguments.stProperties, "lDomains") AND len(arguments.stProperties.lDomains)>
			<cfreturn trim(listFirst(arguments.stProperties.lDomains, "#chr(10)##chr(13)# ")) />
		<cfelse>
			<cfreturn arguments.stProperties.urchinCode />
		</cfif>
	</cffunction>
	
	
	<cffunction name="getSettings" access="public" output="false" returntype="struct">
		<cfargument name="host" required="true" type="string" default="#application.fc.lib.ga.getSettingsHost()#" />
		<cfargument name="flushCache" required="false" type="boolean" default="#request.mode.flushcache#">
		
		<cfset var qSites = queryNew("") />
		<cfset var gaID = "" />

		<cfif arguments.flushcache or not structkeyexists(application.stPlugins.googleanalytics, arguments.host)>
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
						<cfset application.stPlugins.googleanalytics[arguments.host] = getData(gaID) />
						<cfset application.stPlugins.googleanalytics[arguments.host].canonicalDomain = listfirst(application.stPlugins.googleanalytics[arguments.host].lDomains, chr(13) & chr(10)) />
						<cfset application.stPlugins.googleanalytics[arguments.host].accessConfig = application.fc.lib.google.getAccessConfig(stObject=application.stPlugins.googleanalytics[arguments.host], stMetadata=application.fapi.getPropertyMetadata("gaSetting", "googleRefreshToken")) />
					</cfif>

				<cfelse>
					<!--- check for blanket rule --->
					<cfquery datasource="#application.dsn#" name="qSites" cachedwithin="#createTimeSpan(0,0,1,0)#">
						SELECT objectID
						FROM gaSetting
						WHERE bActive = 1 AND (lDomains is null or lDomains like '')
					</cfquery>
					<cfif qSites.recordCount>
						<cfset application.stPlugins.googleanalytics[arguments.host] = getData(qSites.objectID) />
						<cfset application.stPlugins.googleanalytics[arguments.host].canonicalDomain = listfirst(application.stPlugins.googleanalytics[arguments.host].lDomains, chr(13) & chr(10)) />
						<cfset application.stPlugins.googleanalytics[arguments.host].accessConfig = application.fc.lib.google.getAccessConfig(stObject=application.stPlugins.googleanalytics[arguments.host], stMetadata=application.fapi.getPropertyMetadata("gaSetting", "googleRefreshToken")) />
					</cfif>
					
				</cfif>
				
				<cfcatch></cfcatch>
			</cftry>
		</cfif>
		
		<cfif structKeyExists(application.stPlugins.googleanalytics, arguments.host)>
			<cfreturn application.stPlugins.googleanalytics[arguments.host] />
		<cfelse>
			<cfreturn structnew() />
		</cfif>
	</cffunction>
	
</cfcomponent>