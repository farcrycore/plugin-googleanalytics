<cfcomponent extends="farcry.core.packages.rules.rules" displayname="Statistics: Most Popular Content" hint="Adds content suggestions based on the page views reported by Google Analytics" bObjectBroker="1">
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
				ftType="list" ftListData="getContentTypes" ftSelectMultiple="true" />
	<cfproperty name="contentCategories" type="longchar" default="" ftDefault=""
				ftSeq="12" ftFieldSet="Content Filter" ftLabel="Categories" ftHint="Select to filter by items that have one of these categories"
				ftType="category" />
	
	
	<cffunction name="getContentTypes" access="public" output="false" returntype="query" hint="Returns a list of potential content types">
		<cfset var result = querynew("value,name") />
		<cfset var q = "" />
		
		<cfset queryaddrow(result) />
		<cfset querysetcell(result,"value","") />
		<cfset querysetcell(result,"name","-- All Content Types --") />
		
		<cfquery datasource="#application.dsn#" name="q">
			select 	distinct referenceType
			from	#application.dbowner#gaStatistic
		</cfquery>
		
		<cfloop query="q">
			<cfset queryaddrow(result) />
			<cfset querysetcell(result,"value",q.referenceType) />
			<cfif structkeyexists(application.stCOAPI[q.referenceType],"displayname")>
				<cfset querysetcell(result,"name",application.stCOAPI[q.referenceType].displayname) />
			<cfelse>
				<cfset querysetcell(result,"name",q.referenceType) />
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
		
		<cfquery datasource="#application.dsn#" name="q" maxRows="#arguments.stObject.numItems#">
			select		referenceID as objectid,referenceType as typename,hits
			from		#application.dbowner#gaStatistic
			where		1=1
						<cfif len(arguments.stObject.contentTypes)>
							and referenceType in (<cfqueryparam cfsqltype="cf_sql_varchar" list="true" value="#arguments.stObject.contentTypes#" />)
						</cfif>
						<cfif len(arguments.stObject.contentCategories)>
							and referenceID in (
								select		objectid
								from		#application.dbowner#refCategories
								where		categoryid in (<cfqueryparam cfsqltype="cf_sql_varchar" list="true" value="#arguments.stObject.objectCategories#" />)
							)
						</cfif>
						and gaSettingID=<cfqueryparam cfsqltype="cf_sql_varchar" value="#stSetting.objectid#" />
			order by	hits desc
		</cfquery>
		
		<cfreturn q />
	</cffunction>
	
</cfcomponent>