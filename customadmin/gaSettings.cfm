<cfsetting enablecfoutputonly="true" />

<cfimport taglib="/farcry/core/tags/admin/" prefix="admin" />
<cfimport taglib="/farcry/core/tags/formtools" prefix="ft" />

<!--- set up page header --->
<admin:header title="Google Analytics Configuration" writingDir="#session.writingDir#" userLanguage="#session.userLanguage#" />

<!--- Override the client side validation for the filter fields. --->
<cfset stFilterMetaData = structNew() />
<cfset stFilterMetaData.lDomains.ftValidation = "" />
<cfset stFilterMetaData.urchinCode.ftValidation = "" />

<ft:objectadmin 
	typename="gaSetting"
	title="Google Analytics Configuration"
	columnList="lDomains,bActive,urchinCode,types,datetimelastUpdated"
	sortableColumns="datetimelastUpdated"
	lFilterFields="lDomains,urchinCode"
	stFilterMetaData="#stFilterMetaData#"
	sqlorderby="datetimelastUpdated desc"
	plugin="googleanalytics"
	module="/gaSettings.cfm" />

<admin:footer />

<cfsetting enablecfoutputonly="false" />