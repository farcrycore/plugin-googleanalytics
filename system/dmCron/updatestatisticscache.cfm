<cfsetting enablecfoutputonly="true" />
<!--- @@displayname: Google Analytics: Update statistics cache --->

<cfset application.fapi.getContentType(typename="gaStatistic").updateStatistics() />

<cfsetting enablecfoutputonly="false" />