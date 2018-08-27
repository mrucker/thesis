var _renderer  = new TargetRenderer(0, .5, .5, 1000);

var _prerender_n_touch = _renderer.prerender(_renderer.allGray150, _renderer.allGray90, _renderer.evenFill, _renderer.mediumStroke, _renderer.evenOpacity);
var _prerender_y_touch = _renderer.prerender(_renderer.allGray90 , _renderer.allBlack , _renderer.evenFill, _renderer.heavyStroke , _renderer.evenOpacity);

function Target(mouse, x_pct, y_pct, effectiveR, age) {
    
	var isNextTouchNew = true;
	
	var effectiveX = 0;
    var effectiveY = 0;
    
	var xOffsetOnTouch = 0;
	
	var createTime = Date.now();
    var self       = this;
    
    this.getR   = function() { return effectiveR; };
    this.getX   = function() { return effectiveX; };
    this.getY   = function() { return effectiveY; };
    this.getAge = function() { return (Date.now() - createTime) % 1000; };

    this.getData     = function() { 
        return [
            Math.round(self.getX()     ,0),
            Math.round(self.getY()     ,0),
            Math.round(self.getAge()   ,0),
        ];
    };

	this.isNewTouch  = function() {
		
		if(self.isTouched() && isNextTouchNew) {
			isNextTouchNew = false;
			return true;
		}
		
		if(!self.isTouched()) {
			isNextTouchNew = true;
		}

		return false;
    };
	
    this.isTouched  = function() {
        
        var targetX = effectiveX;
        var targetY = effectiveY;
        var mouseX = mouse.getX();
        var mouseY = mouse.getY();

		return dist(targetX,targetY,mouseX,mouseY) <= effectiveR;
    };

    this.getReward = function(canvas) {
		
        var f_classes = self.getFeatures(canvas);		

		//var cnt_index = [0,32,64,96];		
		var lox_index = [0,96,192]
		var loy_index = [0,32,64];
		var dir_index = [0,4,8,12,16,20,24,28];
		var age_index = [1,2,3,4];

		//var r_index = cnt_index[f_classes[0]-1] + dir_index[f_classes[1]-1] + age_index[f_classes[2]-1] + 1;
		var r_index = lox_index[f_classes[0]-1] + loy_index[f_classes[1]-1] + dir_index[f_classes[2]-1] + age_index[f_classes[3]-1];

		//var rewards = [0.29,0.38,0.75,0.62,0.53,0.19,0.53,0.38,0.1,0.23,0.74,0.2,0.21,0.21,0.35,0.07,0.1,0.17,0.21,0.28,0.01,0.13,0.34,0.14,0.03,0.22,0.3,0.34,0.46,0.51,0.68,0.44,0.26,0.52,0.65,0.57,0.24,0.25,0.56,0.49,0.57,0.35,0.49,0.54,0.52,0.3,0.6,0.48,0.34,0.2,0.16,0.15,0,0.24,0.41,0.25,0.09,0.23,0.38,0.02,0.02,0.63,1,0.89,0.34,0.39,0.49,0.43,0.36,0.32,0.43,0.37,0.32,0.33,0.45,0.37,0.33,0.31,0.41,0.33,0.28,0.26,0.32,0.28,0.21,0.27,0.37,0.29,0.23,0.29,0.37,0.3,0.27,0.42,0.53,0.46,0.36,0.39,0.49,0.43,0.36,0.32,0.43,0.37,0.32,0.33,0.45,0.37,0.33,0.31,0.41,0.33,0.28,0.26,0.32,0.29,0.21,0.27,0.37,0.29,0.24,0.29,0.37,0.3,0.27,0.42,0.53,0.46,0.36];
		//var rewards = [0.34,0.38,0.59,0.47,0.35,0.36,0.52,0.35,0.29,0.35,0.5,0.4,0.34,0.3,0.45,0.37,0.15,0.28,0.42,0.33,0.21,0.29,0.47,0.41,0.31,0.28,0.43,0.3,0.23,0.43,1,0.78,0.34,0.28,0.4,0.4,0.25,0.31,0.46,0.33,0.49,0.28,0.43,0.3,0.42,0.23,0.51,0.39,0.21,0.15,0.28,0.06,0.02,0.23,0.45,0.25,0.2,0.19,0.32,0,0.17,0.31,0.46,0.34,0.24,0.39,0.48,0.41,0.39,0.41,0.69,0.45,0.36,0.38,0.5,0.65,0.49,0.32,0.34,0.34,0.4,0.29,0.37,0.3,0.23,0.31,0.42,0.35,0.25,0.31,0.37,0.31,0.3,0.53,0.46,0.32,0.36,0.35,0.51,0.69,0.36,0.32,0.47,0.38,0.3,0.3,0.45,0.36,0.29,0.25,0.37,0.3,0.21,0.23,0.36,0.3,0.21,0.23,0.39,0.32,0.24,0.23,0.36,0.38,0.09,0.32,0.5,0.42,0.3,0.27,0.62,0.31,0.23,0.26,0.41,0.24,0.21,0.22,0.51,0.09,0.23,0.13,0.32,0.12,0.11,0.14,0.21,0.18,0.11,0.17,0.32,0.09,0.12,0.19,0.21,0.14,0.45,0.22,0.5,0.16,0.19,0.38,0.52,0.28,0.66,0.39,0.79,0.62,0.4,0.31,0.64,0.35,0.33,0.23,0.37,0.12,0.24,0.26,0.38,0.19,0.26,0.28,0.41,0.28,0.23,0.28,0.4,0.29,0.3,0.34,0.47,0.33,0.32,0.36,0.43,0.44,0.33,0.34,0.42,0.38,0.33,0.29,0.37,0.34,0.28,0.26,0.34,0.32,0.23,0.26,0.32,0.3,0.22,0.28,0.35,0.33,0.25,0.28,0.34,0.32,0.25,0.37,0.46,0.44,0.32,0.3,0.37,0.54,0.25,0.32,0.38,0.31,0.57,0.23,0.31,0.22,0.24,0.23,0.29,0.26,0.2,0.19,0.13,0.19,0.06,0.23,0.28,0.19,0.15,0.23,0.27,0.23,0.24,0.46,0.27,0.48,0.28,0.46,0.4,0.39,0.33,0.36,0.41,0.48,0.34,0.26,0.26,0.33,0.21,0.21,0.29,0.27,0.12,0.25,0.28,0.25,0.2,0.28,0.32,0.29,0.23,0.28,0.32,0.3,0.25,0.36,0.38,0.36,0.3];
		var rewards = [0.2,0.51,1,0.71,0.44,0.38,0.72,0.58,0.39,0.43,0.7,0.59,0.39,0.38,0.69,0.56,0.36,0.31,0.56,0.4,0.21,0.38,0.68,0.72,0.54,0.32,0.58,0.49,0,0.55,1,1,0.25,0.33,0.62,0.61,0.24,0.28,0.45,0.29,0.53,0.25,0.52,0.25,0.26,0.25,0.74,0.53,0.24,0.07,0.32,0,0,0.22,0.59,0.25,0.09,0.19,0.41,0.11,0.11,0.32,0.6,0.25,0.2,0.47,0.65,0.55,0.44,0.42,0.89,0.52,0.32,0.44,0.64,0.88,0.64,0.37,0.55,0.44,0.58,0.27,0.28,0.32,0.21,0.33,0.51,0.41,0.1,0.34,0.47,0.39,0.27,0.66,0.58,0.35,0.35,0.45,0.71,1,0.42,0.35,0.61,0.51,0.3,0.32,0.57,0.43,0.25,0.28,0.5,0.39,0.22,0.26,0.46,0.4,0.19,0.25,0.48,0.41,0.19,0.31,0.5,0.59,0.24,0.34,0.61,0.44,0.12,0.28,0.86,0.39,0.15,0.19,0.52,0.27,0.12,0.14,0.71,0,0.09,0.1,0.41,0.08,0,0.06,0.35,0.32,0,0.03,0.37,0.08,0.05,0.18,0.26,0.04,0.61,0.19,0.69,0.12,0.14,0.41,0.63,0.27,0.76,0.32,1,0.72,0.18,0.23,0.8,0.27,0,0.2,0.44,0,0.05,0.19,0.4,0.2,0.11,0.21,0.46,0.26,0.14,0.27,0.48,0.3,0.25,0.31,0.55,0.32,0.19,0.45,0.6,0.6,0.38,0.35,0.52,0.47,0.32,0.34,0.49,0.43,0.28,0.32,0.47,0.41,0.25,0.28,0.39,0.37,0.2,0.31,0.45,0.42,0.24,0.32,0.45,0.42,0.24,0.43,0.61,0.54,0.3,0.33,0.53,0.77,0.3,0.29,0.45,0.3,0.68,0.24,0.39,0.22,0.2,0.23,0.39,0.27,0.16,0.15,0.12,0.19,0,0.2,0.35,0.27,0.04,0.24,0.35,0.29,0.21,0.57,0.5,0.63,0.18,0.59,0.51,0.46,0.3,0.18,0.42,0.47,0.04,0.29,0.35,0.35,0.18,0.25,0.36,0.27,0,0.22,0.28,0.25,0.09,0.23,0.33,0.23,0,0.27,0.36,0.31,0.16,0.38,0.45,0.38,0.2];

        return rewards[r_index];
    };
    
    this.getFeatures = function (canvas) {

		var width  = canvas.getResolution(0);
		var height = canvas.getResolution(1);

		var lox_class = effectiveX <= 1/3 * width  ? 1 : effectiveX <= 2/3 * width  ? 2 : 3;
		var loy_class = effectiveY <= 1/3 * height ? 1 : effectiveY <= 2/3 * height ? 2 : 3;

		var mouseX = mouse.getX();
        var mouseY = mouse.getY();

		var dir_radian = Math.atan2(effectiveY - mouseY, effectiveX - mouseX);
		var dir_class  = Math.floor( (dir_radian + 3*Math.PI/8) / (Math.PI/4) );

		if(dir_class <= 0) {
			dir_class += 8;
		}

		var age_value = self.getAge();
		var age_class = age_value <= 250 ? 1 : age_value <= 500 ? 2 : age_value <= 750 ? 3 : 4;

		return [lox_class, loy_class, dir_class, age_class];
    };

    this.draw = function(canvas) {
		x_pct  = x_pct || ((canvas.getResolution(0) - 2*effectiveR) * Math.random() + effectiveR)/canvas.getResolution(0);
        y_pct  = y_pct || ((canvas.getResolution(1) - 2*effectiveR) * Math.random() + effectiveR)/canvas.getResolution(1);

        effectiveX = Math.round(x_pct * canvas.getResolution(0),0);
        effectiveY = Math.round(y_pct * canvas.getResolution(1),0);

        var context = canvas.getContext2d();

        var xOffset = _renderer.xOffset(self.getReward(canvas), 0, 1);
        var yOffset = _renderer.yOffset(self.getAge());

		if(self.isTouched()) {
			xOffsetOnTouch = xOffsetOnTouch || xOffset;
			context.drawImage(_prerender_y_touch,xOffsetOnTouch,yOffset, 200, 200, effectiveX-effectiveR, effectiveY-effectiveR, 2*effectiveR, 2*effectiveR);
		}
		else {
			xOffsetOnTouch = 0;
			context.drawImage(_prerender_n_touch,xOffset,yOffset, 200, 200, effectiveX-effectiveR, effectiveY-effectiveR, 2*effectiveR, 2*effectiveR);
		}
    }

    function dist(x1,y1,x2,y2) {
        return Math.sqrt(Math.pow(x1-x2,2)+Math.pow(y1-y2,2));
    }
}

function TargetRenderer(fadeInTime, fadeOffTime, fadeOutTime, lifespan) {

	var target_radius = 100;

	var rewSteps = 40;
	var ageSteps = 20;

	var width  = 200;
	var height = 200;

    fadeInTime  *= lifespan;
    fadeOffTime *= lifespan;
    fadeOutTime *= lifespan;

    this.evenOpacity = function(ageStep) {
		return ageStep / ageSteps;
    }

    this.gradientRGB = function(rewStep) {
	
        var c_stop0 = [200, 0 ,  0 ];
        var c_stop1 = [100, 0 , 100];
        var c_stop2 = [ 0 , 0 , 200];
		
        var c_val0 = 0.0 * rewSteps; 
        var c_val1 = 0.5 * rewSteps;
        var c_val2 = 1.0 * rewSteps;
		
		var c_wgt0 = 0;
		var c_wgt1 = 0;
		var c_wgt2 = 0;
		
		if(c_val0 <= rewStep && rewStep < c_val1) {
			c_wgt0 = Math.max(0, Math.min((1       ),(c_val1 - rewStep)/(c_val1-c_val0)));
			c_wgt1 = Math.max(0, Math.min((1-c_wgt0),(c_val2 - rewStep)/(c_val2-c_val1))); 
		} 
		if(c_val1 <= rewStep && rewStep <= c_val2) {
			c_wgt1 = Math.max(0, Math.min((1-c_wgt0),(c_val2 - rewStep)/(c_val2-c_val1))); 
		    c_wgt2 = Math.max(0, Math.min((1-c_wgt1),(1                               ))); 
		}			

        var color = [
            c_wgt0*c_stop0[0]+c_wgt1*c_stop1[0]+c_wgt2*c_stop2[0],
            c_wgt0*c_stop0[1]+c_wgt1*c_stop1[1]+c_wgt2*c_stop2[1],
            c_wgt0*c_stop0[2]+c_wgt1*c_stop1[2]+c_wgt2*c_stop2[2]
        ];

        color = color.map(function(c) { return Math.round(c,0); });
        
        return color.join(',');
	}

	this.allBlack = function(rewStep) {
		return "0,0,0";
	}

	this.allGray90 = function(rewStep) {
		return "90,90,90";
	}
	
	this.allGray150 = function(rewStep) {
		return "150,150,150";
	}

	this.mediumStroke = function(rewStep) {
		return 10;
	}
	
	this.heavyStroke = function(rewStep) {
		return 12;
	}
	
	this.evenFill = function(rewStep) {
		return rewStep/rewSteps * target_radius;
	}
	
	this.prerender = function(fill_color, line_color, fill_radius, stroke_width, opacity) {

        var canvas = document.createElement("canvas");

		canvas.width  = rewSteps * width;
		canvas.height = ageSteps * height;

		var context = canvas.getContext("2d");

        for(var rewStep = 0; rewStep < rewSteps; rewStep++) {
            for(var ageStep = 0; ageStep < ageSteps; ageStep++) {
				
				var xOffset = rewStep * width  + target_radius;
                var yOffset = ageStep * height + target_radius;
                			
				var center_radius = fill_radius(rewStep);
				var stroke_weight = stroke_width(rewStep);
				var stroke_begins = target_radius-(stroke_weight/2);
				
				var fill_style = "rgba(" + fill_color(rewStep) + "," + opacity(ageStep) + ")";
				var line_style = "rgba(" + line_color(rewStep) + "," + opacity(ageStep) + ")";

				context.beginPath();
				context.fillStyle = "rgb(255,255,255)";
				context.arc(xOffset, yOffset, target_radius, 0, 2 * Math.PI);
				context.fill();
				
				context.beginPath();
				context.fillStyle = fill_style;
				context.arc(xOffset, yOffset, center_radius, 0, 2 * Math.PI);
				context.fill();
				
				context.beginPath();
				context.lineWidth = stroke_weight;
				context.strokeStyle = line_style;
				context.arc(xOffset, yOffset, stroke_begins, 0, 2 * Math.PI);
				context.stroke();
			}
        }

        return canvas;
    }
	
    this.xOffset = function (reward, min, max) {
		return 200 * Math.round((reward-min)/(max-min) * (rewSteps-1));
    }
    
    this.yOffset = function(age) {
		var o_value   = 0;

        if (age <= fadeInTime){
            o_value = age/fadeInTime;
        }

        if (fadeInTime <= age && age <= fadeInTime+fadeOffTime){
            o_value = 1;
        }

        if (fadeInTime+fadeOffTime <= age && age <= fadeInTime+fadeOffTime+fadeOutTime){
            o_value = (fadeInTime+fadeOffTime+fadeOutTime-age) / fadeOutTime;
        }

        if (age >= fadeInTime+fadeOffTime+fadeOutTime) {
            o_value = 0;
        }		
		
        return 200 * Math.round(o_value * (ageSteps-1));
    }

	this.sample = function(canvas, x,y) {
		
		var context     = canvas.getContext2d();
		var x_step_size = 125;
		var radius      = 50;
		
		for(var r = -1; r <= 1; r+=.05) {
			
			var yOffset = _renderer.yOffset(985);
			var xOffset = _renderer.xOffset(r);
			
			context.drawImage(_prerender, xOffset, yOffset, 200, 200, (r+1)*x_step_size, 0, 2*radius, 2*radius);
		}

		var highlight = function(r) {
			context.beginPath();
			context.fillStyle = "rgba(256,256,256,1)";
			context.arc((r+1)*x_step_size + radius, 0 + radius, radius - 4, 0, 2 * Math.PI);
			context.fill();
			context.drawImage(_prerender, _renderer.xOffset(r), _renderer.yOffset(0), 200, 200, (r+1)*x_step_size, 0, 2*radius, 2*radius);
		}
		
		highlight(-1.0);
		highlight(-0.5);
		highlight( 0.0);
		highlight( 0.5);
		highlight( 1.0);
	}
}