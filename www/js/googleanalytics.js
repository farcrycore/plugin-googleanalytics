if (!window.GA) {
	var GA = {};
	
	(function(){
		GA.linechart = function drawLineChart(id, data, offsetdata, meta, width, height, randomize){
			randomize = randomize || 0, xvalues = meta.xvalues.slice(), xlabels = meta.xlabels.slice(), newdata = [], newoffsetdata = [], newxvalues = [], newxlabels = [];
			
			// more than 100 points doesn't render very well as a line chart (might look at wider charts in these cases later)
			while (data.length > 100){
				newdata = [], newoffsetdata = [], newxvalues = [], newxlabels = [];
				
				for (var i=0; i<xlabels.length; i++)
					newxlabels[i] = [];
				
				for (var i=0; i<data.length; i+=2){
					newdata.push(data[i]+(data[i+1] || 0));
					newoffsetdata.push(offsetdata[i]+(offsetdata[i+1] || 0));
					newxvalues.push(xvalues[i]);
					for (var j=0; j<xlabels.length; j++)
						newxlabels[j].push(xlabels[j][i]);
				}
				
				data = newdata, offsetdata = newoffsetdata, xvalues = newxvalues, xlabels = newxlabels;
			}
			
			if (randomize) {
				for (var i = 0; i < data.length; i++) {
					data[i] += Math.floor(Math.random() * randomize);
					if (offsetdata)
						offsetdata[i] += Math.floor(Math.random() * randomize);
				}
			}
			
			var r = Raphael(id);
			r.linechart(20, 20, width - 40, height - 40, xvalues, (offsetdata ? [ data, offsetdata ] : data), {
				axis: "0 0 0 1",
				shade: true
			}).hoverColumn(function(){
				this.tags = r.set();
				
				for (var i = 0, ii = this.y.length; i < ii; i++) {
					this.tags.push(r.tag(this.x, this.y[i], xlabels[i][xvalues.indexOf(this.axis)] + ": " + this.values[i], 160, 10).insertBefore(this).attr([{
						fill: "#fff"
					}, {
						fill: Raphael.g.colors[i]
					}]));
				}
			}, function(){
				this.tags && this.tags.remove();
			});
			
			return r;
		};
	})();
	
	(function(){
		GA.dotchart = function drawDotChart(id, data, offsetdata, meta, width, height, randomize){
			randomize = randomize || 0;
			
			if (randomize) {
				for (var i = 0; i < data.length; i++) 
					data[i] += Math.floor(Math.random() * randomize);
			}
			
			var r = Raphael(id);
			var chart = r.dotchart(0, 0, width, height, meta.xvalues, meta.yvalues, data, {
				symbol: "o",
				max: 10,
				heat: true,
				axis: "0 0 1 1",
				axisxstep: meta.xlabels.length-1,
				axisystep: meta.ylabels.length-1,
				axisxtype: " ",
				axisxlabels: meta.xlabels,
				axisytype: " ",
				axisylabels: meta.ylabels
			}).hover(function(){
				this.marker = this.marker || r.tag(this.x, this.y, this.value, 0, this.r + 2).insertBefore(this);
				this.marker.show();
			}, function(){
				this.marker && this.marker.hide();
			});
			
			return r;
		};
	})();
	
	(function(){
		var state = {
			url: "",
			type: "linechart",
			period: 'week',
			path: 'exact',
			data: {}
		};
		
		GA.drawCharts = function(){
			for (var i=0, ii=Raphael.g.colors.length, color=[]; i<ii; i++){
				color = Raphael.g.colors[i].slice(5,-1).split(",").map(function(v){ return parseFloat(v || "0"); });
				$j("#graph-colour-"+i.toString()).css("background-color",Raphael.hsb2rgb(color[0],color[1],color[2]).hex);
			}
			
			$j(".chart").each(function(){
				var self = $j(this).html(""), 
					data = state.data.data[self.data("metric").toLowerCase()], 
					offsetdata = state.data.offsetdata[self.data("metric").toLowerCase()], 
					meta = state.data[state.type];
				
				if (state.data[state.type].height)
					self.height(state.data[state.type].height);
				if (state.data[state.type].width)
					self.width(state.data[state.type].width);
				
				GA[state.type](self[0], data, offsetdata, meta, self.width(), self.height(),0);
			});
		};
		
		GA.updateCharts = function(key, val){
			if (key && state[key] !== val) {
				state[key] = val;
				
				if (key === "url" && state.url.length && !state.url.indexOf("?")) 
					state.url += "?";
			}
			
			if (state.url.length === "") 
				return;
			
			if (key === "type") {
				if (state.data[state.type].disabled) {
					$j("#charts").html("<br><p id='errorMsg'>"+state.data[state.type].disabled+"</p>");
				}
				else {
					$j("#charts").html($j("#" + state.type + "_template").html());
					GA.drawCharts();
				}
			}
			else {
				$j("#charts").html($j("#" + state.type + "_template").html());
				if (key === "url" || key === "period" || key === "path") {
					$j.getJSON(state.url + "&period=" + state.period + "&path=" + state.path + "&periodoffset=1", function(data){
						state.data = data;
						
						// convert various array-of-number-strings values to arrays-of-numbers values
						for (var metric in state.data.data){
							if (["timeonpage","week","quarter","bounces","entrances","uniquepageviews","newvisits","dayofweek","month","pageviews","exits"].indexOf(metric) > -1){
								state.data.data[metric] = state.data.data[metric].map(function(v){ return parseInt(v); });
								state.data.offsetdata[metric] = state.data.offsetdata[metric].map(function(v){ return parseInt(v); });
							}
						}
						if (state.data.data["hour"]){
							state.data.data["hour"] = state.data.data["hour"].map(function(v){ return parseInt(v); });
							state.data.offsetdata["hour"] = state.data.offsetdata["hour"].map(function(v){ return parseInt(v); });
						}
						if (state.data.linechart.xvalues)
							state.data.linechart.xvalues = state.data.linechart.xvalues.map(function(v){ return parseInt(v); });
						if (state.data.dotchart.xvalues)
							state.data.dotchart.xvalues = state.data.dotchart.xvalues.map(function(v){ return parseInt(v); });
						if (state.data.dotchart.yvalues)
							state.data.dotchart.yvalues = state.data.dotchart.yvalues.map(function(v){ return parseInt(v); });
						
						
						if (state.data[state.type].disabled) {
							$j("#charts").html("<br><p id='errorMsg'>"+state.data[state.type].disabled+"</p>");
						}
						else {
							GA.drawCharts();
						}
					});
				}
			}
		};
	})();
	
	$j(function(){
		$j(document).delegate("a.state-change", "click", function(e){
			var self = $j(e.target);
			
			self.css("font-weight","bold").siblings("[data-key="+self.data("key")+"]").css("font-weight","normal");
			
			GA.updateCharts(self.data("key"),self.data("value"));
			
			return false;
		});
	});
}