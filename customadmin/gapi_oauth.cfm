<cfsetting enablecfoutputonly="true" />

<cfif isdefined("url.clientid") and isdefined("url.clientsecret")>
	<cflocation url="#application.fc.lib.ga.getAuthorisationURL(clientID=url.clientid,redirectURL='http://#cgi.http_host##application.url.webtop#/admin/customadmin.cfm?plugin=googleanalytics&module=gapi_oauth.cfm',state='#url.clientid#|#url.clientsecret#|#url.proxy#')#" addtoken="false" />
<cfelseif isdefined("url.code")>
	<cfset clientID = listgetat(url.state,1,"|") />
	<cfset clientSecret = listgetat(url.state,2,"|") />
	<cfif listlen(url.state,"|") eq 3>
		<cfset proxy = listgetat(url.state,3,"|") />
	<cfelse>
		<cfset proxy = "" />
	</cfif>
	
	<cfset refreshToken = application.fc.lib.ga.getRefreshToken(url.code,clientID,clientSecret,"http://#cgi.http_host##application.url.webtop#/admin/customadmin.cfm?plugin=googleanalytics&module=gapi_oauth.cfm",proxy) />
	
	<cfoutput><script type="text/javascript">
		window.opener.updateRefreshToken('#refreshToken#');
		window.close();
	</script></cfoutput>
</cfif>

<cfsetting enablecfoutputonly="false" />