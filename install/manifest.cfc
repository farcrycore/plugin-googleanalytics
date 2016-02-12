<cfcomponent extends="farcry.core.webtop.install.manifest" name="manifest">

	<cfset this.name = "Google Analytics" />
	<cfset this.description = "<strong>Google Analytics</strong> plugin makes it very easy to add basic request tracking, as well as tracking of downloads and outbound links." />
	<cfset this.lRequiredPlugins = "" />
	<cfset this.taglibraryprefix = "ga" />
	<cfset addSupportedCore(majorVersion="5") />
	<cfset addSupportedCore(majorVersion="6") />
	<cfset addSupportedCore(majorVersion="7") />

</cfcomponent>

