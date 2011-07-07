<cfsetting enablecfoutputonly="yes">
<!--- @@displayname: Track event --->

<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />
<cfimport taglib="/farcry/core/tags/navajo" prefix="nj" />

<!--- load/cache jquery --->
<skin:loadJS id="jquery" />
<skin:loadJS id="fcga" baseHREF="/farcry/plugins/googleanalytics/www/js/" lFiles="jquery.gatracker.js" />

<!--- Attributes --->
<cfparam name="attributes.objectid" default="" /><!--- The objectid of this page. If this and pageurl are both not specified, the script_name & query_string are tracked. --->
<cfparam name="attributes.typename" default="" /><!--- The type of the page. Can be used with objectid to improve performance --->
<cfparam name="attributes.stObject" default="" /><!--- The property struct for this page. Can be substituted for objectid for slightly better performance. --->
<cfparam name="attributes.url" default="" /><!--- Override the page URL that google tracks. Defaults to the FU if there is one, or /typename/label-with-hyphens if there isn't --->
<cfparam name="attributes.host" default="#cgi.http_host#" />
<cfparam name="attributes.customVars" default="#arraynew(1)#" /><!--- Array of up to { name, value, scope } structs. Note that these values are subject to GA custom variables behaviour, particularly with regard to scopes. Recommended usage is to set every used session or visitor variable on every request. --->

<cfif thistag.ExecutionMode eq "start">
	<!--- grab config --->
	<cfset stSetting = application.fapi.getContentType(typename="gaSetting").getSettings(attributes.host) />
	
</cfif>

<cfif thistag.ExecutionMode eq "end" AND NOT structIsEmpty(stSetting)>

	<cfif not isstruct(attributes.stObject) and len(attributes.objectid)>
		<cfset attributes.stObject = application.fapi.getContentObject(objectid=attributes.objectid,typename=attributes.typename) />
	</cfif>
	<cfif isstruct(attributes.stObject) and not structkeyexists(attributes.stObject,"typename")>
		<cfset attributes.stObject.typename = application.coapi.findType(attributes.stObject.objectid) />
	</cfif>
	<cfif not isstruct(attributes.stObject) and not len(attributes.url)>
		<cfif isDefined("request.stObj.objectID") and isValid("uuid",request.stObj.objectID)><!--- not a types webskin --->
			<cfset attributes.stObject = request.stObj />
		<cfelse><!--- Just use the current url --->
			<cfset attributes.url = application.fapi.fixURL() />
		</cfif>
	</cfif>
	
	<!--- Handle dynamic custom variable attributes --->
	<cfset cvScopes = structnew() />
	<cfset cvScopes.visitor = 1 />
	<cfset cvScopes.session = 2 />
	<cfset cvScopes.page = 3 />
	<cfloop collection="#attributes#" item="attr">
		<cfif refindnocase("^(session|visitor|page)_",attr)>
			<cfset stCV = structnew() />
			<cfset stCV.scope = cvScopes[rereplacenocase(attr,"^(session|visitor|page)_.*$","\1")] />
			<cfset stCV.name = rereplacenocase(attr,"^(session|visitor|page)_(.*)$","\2") />
			<cfset stCV.value = attributes[attr] />
			<cfset arrayappend(attributes.customVars,stCV) />
		</cfif>
	</cfloop>
	<!--- Convert custom variables to JSON --->
	<cfset thistag.customVarsJSON = "" />
	<cfloop from="1" to="#arraylen(attributes.customVars)#" index="i">
		<cfset thistag.customVarsJSON = listappend(thistag.customVarsJSON,'{ "name":"#attributes.customVars[i].name#", "value":"#attributes.customVars[i].value#", "scope":#attributes.customVars[i].scope#  }') />
	</cfloop>
	<cfset thistag.customVarsJSON = "[" & thistag.customVarsJSON & "]" />
	
	<cfif NOT structkeyexists(request,"gaadded")>
		<cfset request.gaadded = true />
		
		<cfif not len(attributes.url)>
			<cfif isStruct(attributes.stObject) and not len(attributes.url)>
				<cfif attributes.stObject.typename eq "farCOAPI">
					<cfset attributes.url = application.fapi.fixURL() />
					<cfif find("/index.cfm?",attributes.url)>
						<cfset attributes.url = "/#application.stCOAPI[attributes.stObject.name].fuAlias#" />
						<cfif len(url.view) and url.view neq "displayPageStandard">
							<cfset attributes.url = attributes.url & "/#application.stCOAPI[attributes.stObject.name].stWebskins[url.view].fuAlias#" />
						</cfif>
						<cfif len(url.bodyview) and url.bodyview neq "displayTypeBody">
							<cfset attributes.url = attributes.url & "/#application.stCOAPI[attributes.stObject.name].stWebskins[url.bodyview].fuAlias#" />
						</cfif>
					</cfif>
				<cfelse>
					<cfif len(attributes.stObject.objectid) AND structKeyExists(application.stCoapi["#attributes.stObject.typename#"], "bUseInTree") AND application.stCoapi["#attributes.stObject.typename#"].bUseInTree>
						<!--- look up the object's parent navigaion node --->
						<nj:getNavigation objectId="#attributes.stObject.objectId#" r_stobject="stNav" />
						
						<!--- if the object is in the tree this will give us the node --->
						<cfif isStruct(stNav) and structKeyExists(stNav, "objectid") AND len(stNav.objectid)>
							<cfset attributes.url = application.fapi.getLink(objectid=stNav.objectID) />
						<cfelse>
							<cfset attributes.url = application.fapi.getLink(objectid=attributes.stObject.objectid) />
						</cfif>
					<cfelse>
						<cfset attributes.url = application.fapi.getLink(objectid=attributes.stObject.objectid) />
					</cfif>
					
					<cfif find("/index.cfm?",attributes.url)>
						<cfset attributes.url = "/#application.stCOAPI[attributes.stObject.typename].fuAlias#/#rereplace(rereplace(attributes.stObject.label,'\s+','-','ALL'),'[^\w\-]','','ALL')#" />
					</cfif>
					<cfif len(url.view) and url.view neq "displayPageStandard" and (not structkeyexists(attributes.stObject,"displaymethod") or attributes.stObject.displaymethod neq url.view)>
						<cfset attributes.url = attributes.url & "/#application.stCOAPI[attributes.stObject.typename].stWebskins[url.view].fuAlias#" />
					</cfif>
					<cfif len(url.bodyview) and url.bodyview neq "displayBody">
						<cfset attributes.url = attributes.url & "/#application.stCOAPI[attributes.stObject.typename].stWebskins[url.bodyview].fuAlias#" />
					</cfif>
				</cfif>
			</cfif>
		</cfif>
		
		<cfoutput>
			<script type="text/javascript">
				var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
				document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
			</script>
			<script type="text/javascript">
				var figureOutLink = function(el,ev,opts) { 
					var self = $j(el);
					var title = "";
					title = (self.attr("title") ? self.attr("title") : el.innerHTML);
					return '/downloads/'+title.replace(/<[^>]+>/g,'-').replace(/[^\w]+/g,'-');
				};
				if($j && $j.ga) {
					$j.ga.setTracker(_gat._getTracker("#stSetting.urchinCode#"),'#stSetting.types#');
					$j("a").track(); // track external links, files, email addresses
					$j("a[href*=download.cfm]").track({ urlfn:figureOutLink });
					// track obfusicated dmFile (and any other configured) types
					<cfloop list="#stSetting.types#" index="thistype">
						$j("a.#thistype#").track({ urlfn:figureOutLink });
					</cfloop>
				}
			</script>
		</cfoutput>
	</cfif>
	
	<cfoutput>
		<script type="text/javascript">
			if($j && $j.ga) {
				$j.ga.trackURL('#attributes.url#',#thistag.customVarsJSON#);
			}
		</script>
	</cfoutput>
</cfif>

<cfsetting enablecfoutputonly="no">