<cfcomponent displayname="Google Analytics Statistic" description="Cached and flattened stats for FarCry content" extends="farcry.core.packages.types.types" bObjectBroker="0" bRefObjects="0">
	<cfproperty name="referenceID" type="uuid" />
	<cfproperty name="referenceType" type="string" />
	<cfproperty name="hits" type="integer" />
	<cfproperty name="gaSettingID" type="uuid" ftJoin="gaSetting" />
	
	
	<cffunction name="updateStatistics" access="public" returntype="struct" output="false">
		<cfargument name="gaSettingID" type="uuid" required="false" />
		<cfargument name="stSetting" type="struct" required="false" />
		
		<cfset var st = structnew() />
		<cfset var stData = structnew() />
		<cfset var stFU = structnew() />
		<cfset var stStat = structnew() />
		<cfset var qExists = "" />
		<cfset var accessToken = "" />
		
		<cfif not structkeyexists(arguments,"stSetting")>
			<cfif structkeyexists(arguments,"gaSettingID")>
				<cfset arguments.stSetting = application.fapi.getContentObject(typename="gaSetting",objectid=arguments.gaSettingID) />
			<cfelse>
				<cfset arguments.stSetting = application.fapi.getContentType(typename="gaSetting").getSettings() />
			</cfif>
		</cfif>
		
		<cfset accessToken = application.fc.lib.ga.getAccessToken(listrest(arguments.stSetting.googleRefreshToken,":"),arguments.stSetting.googleClientID,arguments.stSetting.googleClientSecret,arguments.stSetting.googleProxy) />
		
		<cfset stData = application.fc.lib.ga.getDataAll(
			dimensions = "ga:pagepath",
			metrics = "ga:pageviews",
			startDate = dateadd("d",-arguments.stSetting.cacheDays,now()),
			endDate = now(),
			accessToken = accessToken,
			profileID = arguments.stSetting.googleProfileID) />
		
		
		<cfquery datasource="#application.dsn#">
			update	#application.dbowner#gaStatistic
			set		hits=<cfqueryparam cfsqltype="cf_sql_bigint" value="0" />		
			where	gaSettingID=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.stSetting.objectid#" />
		</cfquery>			
		
		<cfloop query="stData.results">
			<cfset stFU = application.fc.factory.farFU.getFUData(listfirst(stData.results.pagepath,"?")) />
			<cfif structkeyexists(stFU,"objectid")>
				<cfquery datasource="#application.dsn#" name="qExists">
					select	objectid
					from	#application.dbowner#gaStatistic
					where	referenceid=<cfqueryparam cfsqltype="cf_sql_varchar" value="#stFU.objectid#" />
							and gaSettingID=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.stSetting.objectid#" />
				</cfquery>
				<cfif qExists.recordcount>
					<cfquery datasource="#application.dsn#">
						update	#application.dbowner#gaStatistic
						set		hits= hits+ <cfqueryparam cfsqltype="cf_sql_bigint" value="#stData.results.pageviews#" />,
								datetimelastupdated=<cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#" />
						where	objectid=<cfqueryparam cfsqltype="cf_sql_varchar" value="#qExists.objectid[1]#" />
								and gaSettingID=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.stSetting.objectid#" />
					</cfquery>
				<cfelseif len(stFU.type)>
					<cfset stStat = application.fapi.getNewContentObject(typename="gaStatistic") />
					<cfset stStat.referenceID = stFU.objectid />
					<cfset stStat.referenceType = stFU.type />
					<cfset stStat.hits = stData.results.pageviews />
					<cfset stStat.gaSettingID = arguments.stSetting.objectid />
					<cfset setData(stProperties=stStat) />
				</cfif>
			</cfif>
		</cfloop>
		
		<cfset application.fc.lib.objectbroker.flushTypeWatchWebskins(objectid=createuuid(),typename="gaStatistic") />
		
		<cfreturn stData />
	</cffunction>
	
</cfcomponent>