<cfsetting enablecfoutputonly="true">

<cfimport taglib="/farcry/core/tags/formtools" prefix="ft" />

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
	sqlorderby="datetimelastUpdated desc" />

<cfsetting enablecfoutputonly="false">