<cfsetting enablecfoutputonly="Yes">

<cfparam name="application.stPlugins" default="#structnew()#" />
<cfparam name="application.stPlugins.googleanalytics" default="#structnew()#" />

<cfset application.stPlugins.googleanalytics.gatrackerinwww = fileexists("#application.path.project#/www/googleanalytics/js/jquery.gatracker.js") />
<cfset application.stPlugins.googleanalytics.settings = structnew() />

<cfsetting enablecfoutputonly="no">