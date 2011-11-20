<cfsetting enablecfoutputonly="yes">
<!--- @@displayname: Track event --->

<!--- Attributes --->
<cfparam name="attributes.objectid" default="" /><!--- The objectid of this page. If this and pageurl are both not specified, the script_name & query_string are tracked. --->
<cfparam name="attributes.typename" default="" /><!--- The type of the page. Can be used with objectid to improve performance --->
<cfparam name="attributes.stObject" default="" /><!--- The property struct for this page. Can be substituted for objectid for slightly better performance. --->
<cfparam name="attributes.url" default="" /><!--- Override the page URL that google tracks. Defaults to the FU if there is one, or /typename/label-with-hyphens if there isn't --->
<cfparam name="attributes.host" default="" />
<cfparam name="attributes.customVars" default="#arraynew(1)#" /><!--- Array of up to { name, value, scope } structs. Note that these values are subject to GA custom variables behaviour, particularly with regard to scopes. Recommended usage is to set every used session or visitor variable on every request. --->

<cfif thistag.ExecutionMode eq "end">
	<!--- Override default tracked object --->
	<cfif not isstruct(attributes.stObject) and len(attributes.objectid)>
		<cfset application.fc.lib.ga.setTrackableURL(stObject=application.fapi.getContentObject(objectid=attributes.objectid,typename=attributes.typename)) />
	<cfelseif isstruct(attributes.stObject) and not structkeyexists(attributes.stObject,"typename")>
		<cfset attributes.stObject.typename = application.coapi.findType(attributes.stObject.objectid) />
		<cfset application.fc.lib.ga.setTrackableURL(stObject=attributes.stObject) />
	</cfif>
	
	<!--- Handle dynamic custom variable attributes --->
	<cfloop collection="#attributes#" item="attr">
		<cfif refindnocase("^(session|visitor|page)_",attr)>
			<cfset stCV = structnew() />
			<cfset stCV.scope = rereplacenocase(attr,"^(session|visitor|page)_.*$","\1") />
			<cfset stCV.name = rereplacenocase(attr,"^(session|visitor|page)_(.*)$","\2") />
			<cfset stCV.value = attributes[attr] />
			<cfset arrayappend(attributes.customVars,stCV) />
		</cfif>
	</cfloop>
	<cfloop from="1" to="#arraylen(attributes.customVars)#" index="i">
		<cfset application.fc.lib.ga.setCustomVar(name=attributes.customVars[i].name,value=attributes.customVars[i].value,scope=attributes.customVars[i].scope) />
	</cfloop>
	
	<!--- Override the host used to determine which settings to apply --->
	<cfif len(attributes.host)>
		<cfset application.fc.lib.ga.setSettingsHost(attributes.host) />
	</cfif>
</cfif>

<cfsetting enablecfoutputonly="no">