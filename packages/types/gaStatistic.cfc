<cfcomponent displayname="Google Analytics Statistic" description="Cached and flattened stats for FarCry content" extends="farcry.core.packages.types.types" bObjectBroker="0" bRefObjects="0">
	<cfproperty name="referenceID" type="uuid" />
	<cfproperty name="referenceType" type="string" />
	<cfproperty name="hits" type="integer" />
	
	
	<cffunction name="updateStatistics" access="public" returntype="struct" output="false">
		<cfargument name="gaSettingID" type="uuid" required="false" />
		<cfargument name="stSetting" type="struct" required="false" />
		
		<cfset var st = structnew() />
		<cfset oGA = application.fapi.getContentType(typename="gaSetting") />
		<cfset stData = structnew() />
		<cfset stFU = structnew() />
		<cfset stStat = structnew() />
		<cfset qExists = "" />
		
		<cfif not structkeyexists(arguments,"stSetting")>
			<cfif structkeyexists(arguments,"gaSettingID")>
				<cfset arguments.stSetting = oGA.getData(objectid=arguments.gaSettingID) />
			<cfelse>
				<cfset arguments.stSetting = oGA.getSettings() />
			</cfif>
		</cfif>
		
		<cfset stData = oGA.getGADataAll(
			dimensions = "ga:pagepath",
			metrics = "ga:pageviews",
			startDate = dateadd("d",-arguments.stSetting.cacheDays,now()),
			endDate = now()) />
		
		
		<cfquery datasource="#application.dsn#">
			update	#application.dbowner#gaStatistic
			set		hits=<cfqueryparam cfsqltype="cf_sql_bigint" value="0" />							
		</cfquery>			
		
		<cfloop query="stData.results">
			<cfset stFU = application.fc.factory.farFU.getFUData(listfirst(stData.results.pagepath,"?")) />
			<cfif structkeyexists(stFU,"objectid")>
				<cfquery datasource="#application.dsn#" name="qExists">
					select	objectid
					from	#application.dbowner#gaStatistic
					where	referenceid=<cfqueryparam cfsqltype="cf_sql_varchar" value="#stFU.objectid#" />
				</cfquery>
				<cfif qExists.recordcount>
					<cfquery datasource="#application.dsn#">
						update	#application.dbowner#gaStatistic
						set		hits= hits+ <cfqueryparam cfsqltype="cf_sql_bigint" value="#stData.results.pageviews#" />,
								datetimelastupdated=<cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#" />
						where	objectid=<cfqueryparam cfsqltype="cf_sql_varchar" value="#qExists.objectid[1]#" />
					</cfquery>
				<cfelse>
					<cfset stStat = application.fapi.getNewContentObject(typename="gaStatistic") />
					<cfset stStat.referenceID = stFU.objectid />
					<cfset stStat.referenceType = stFU.type />
					<cfset stStat.hits = stData.results.pageviews />
					<cfset setData(stProperties=stStat) />
				</cfif>
			</cfif>
		</cfloop>
		
		<cfset application.fc.lib.objectbroker.flushTypeWatchWebskins(objectid=createuuid(),typename="gaStatistic") />
		
		<cfreturn stData />
	</cffunction>
	
</cfcomponent>