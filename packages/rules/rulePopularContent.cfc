<cfcomponent extends="farcry.core.packages.rules.rules" displayname="Google Analytics: Most Popular Content" hint="Adds content suggestions based on the page views reported by Google Analytics" bObjectBroker="1">
	<cfproperty name="title" type="string" default="Most Popular Content" ftDefault="Most Popular Content"
				ftSeq="1" ftFieldSet="General" ftLabel="Title"
				ftType="string" />
	<cfproperty name="intro" type="longchar" default="" ftDefault=""
				ftSeq="2" ftFieldSet="General" ftLabel="Intro" />
	<cfproperty name="numItems" type="integer" default="5" ftDefault="5"
				ftSeq="2" ftFieldSet="General" ftLabel="Number of Items"
				ftType="integer" />
	
	<cfproperty name="contentTypes" type="longchar" default="" ftDefault=""
				ftSeq="11" ftFieldSet="Content Filter" ftLabel="Types"
				ftType="list" ftListData="getContentTypes" ftSelectMultiple="true"
				ftHint="Do not select too many - there is a total character limit of 120" />
	<cfproperty name="contentRegex" type="string" ftDefault=""
				ftSeq="13" ftFieldSet="Content Filter" ftLabel="URL Regular Expression"
				ftHint="Character limit of 120" />

	
	<cffunction name="getContentTypes" access="public" output="false" returntype="query" hint="Returns a list of potential content types">
		<cfset var result = querynew("value,name") />
		<cfset var typename = "" />
		
		<cfset queryaddrow(result) />
		<cfset querysetcell(result,"value","") />
		<cfset querysetcell(result,"name","-- All Content Types --") />
		
		<cfloop collection="#application.stCOAPI#" item="typename">
			<cfif not application.fapi.getContentTypeMetadata(typename, "bSystem", false) and application.fapi.getContentTypeMetadata(typename, "displayname", "") neq "">
				<cfset queryaddrow(result) />
				<cfset querysetcell(result, "value", typename) />
				<cfset querysetcell(result, "name", application.fapi.getContentTypeMetadata(typename, "displayname", "")) />
			</cfif>
		</cfloop>
		
		<cfquery dbtype="query" name="result">
			select		*
			from		result
			order by	name
		</cfquery>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="getObjects" access="public" output="false" returntype="query" hint="Returns the content to display">
		<cfargument name="stObject" type="struct" required="true" />
		
		<cfset var q = "" />
		<cfset var stSetting = application.fapi.getContentType(typename="gaSetting").getSettings() />
		<cfset var stFU = "" />
		<cfset var qResult = "" />
		<cfset var stMap = structnew() />
		<cfset var stArgs = {
			dimensions="ga:customVarValue4,ga:customVarValue5",
			metrics="ga:pageviews",
			sort="-ga:pageviews",
			filters="",
			startDate=dateformat(dateadd("d", -stSetting.cacheDays, now()), "yyyy-mm-dd"),
			endDate=dateformat(now(), "yyyy-mm-dd"),
			maxResults=arguments.stObject.numItems * 3,
			profileID=stSetting.googleProfileID,
			accessConfig=stSetting.accessConfig
		} />

		<cfif len(arguments.stObject.contentTypes)>
			<cfset stArgs.filters = listappend(stArgs.filters, "ga:customVarValue4=~^(#changelistdelims(arguments.stObject.contentTypes, '|')#)$", ";") />
		</cfif>

		<cfif len(arguments.stObject.contentRegex)>
			<cfset stArgs.filters = listappend(stArgs.filters, "ga:pagePath=~" & arguments.stObject.contentRegex, ";") />
		</cfif>
		
		<cfset qResult = application.fc.lib.ga.getData(argumentCollection=stArgs).results />

		<cfset q = querynew("objectid,typename,hits", "varchar,varchar,numeric") />
		<cfloop query="qResult">
			<cfif structKeyExists(stMap, qResult.customVarValue5)>
				<cfset querySetCell(q, "hits", q.hits[stMap[stFU.customVarValue5]] + qResult.pageviews, stMap[qResult.customVarValue5]) />
			<cfelse>
				<cfset queryAddRow(q) />
				<cfset querySetCell(q, "objectid", qResult.customVarValue5) />
				<cfset querySetCell(q, "typename", qResult.customVarValue4) />
				<cfset querySetCell(q, "hits", qResult.pageviews) />
				<cfset stMap[qResult.customVarValue5] = q.recordcount />
			</cfif>
		</cfloop>
		<cfquery dbtype="query" name="q" maxrows="#arguments.stObject.numItems#">
			select * from q order by hits desc
		</cfquery>

		<cfreturn q />
	</cffunction>
	
</cfcomponent>