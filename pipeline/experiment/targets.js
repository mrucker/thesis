function Targets(mouse)
{
    var targets = [];
    var process = poissonProcess.create(50, function () { targets.push(new Target(mouse))} );
    
    this.startAppearing = function() {
        process.start();
    }
    
    this.stopAppearing = function() {
        process.stop();
    }    
    
    this.draw = function(canvas){
        targets.forEach(function(target){ target.draw(canvas); });
        targets = targets.filter(function(target) {return !target.isDead();} );
    }
}

function Target(mouse)
{
    var d = 200;
    var x = null;
    var y = null;
    var r = 0;
    var g = 200;
    var b = 0;

    return new TargetBase(x,y,d,r,g,b, mouse);
}

function TargetBase(x,y,d,r,g,b, mouse)
{
    var fadeInTime   = 0;
    var fadeOutTime  = 500;
    var fadeOffTime  = 500;
    var createTime = Date.now();

    this.getCreateTime = function() { return createTime };
    this.getX          = function() { return x; };
    this.getY          = function() { return y; };
    this.isDead        = function() { return (Date.now() - createTime) > (fadeInTime+fadeOffTime+fadeOutTime); }

    this.draw = function(canvas){
        
        x = x || (canvas.getWidth()  - d) * Math.random() + d/2; //[d/2,height-d/2]
        y = y || (canvas.getHeight() - d) * Math.random() + d/2; //[d/2, width-d/2]
        
        var context   = canvas.getContext2d();
        
        context.save();
        
        context.fillStyle = fillStyle();
        context.beginPath();
        context.moveTo(x,y);
        context.arc(x, y, d/2, 0, 2 * Math.PI);
        context.fill();
        
        context.restore();
    }
    
    function dist(x1,y1,x2,y2) {
        return Math.sqrt(Math.pow(x1-x2,2)+Math.pow(y1-y2,2));
    }

    function fillStyle() {
        return 'rgba('+ rgb() +','+ a() +')';
    }
    
    function rgb() {
            var targetX = x;
            var targetY = y;
            var mouseX = mouse.getX();
            var mouseY = mouse.getY();
        
        if( Math.abs(mouseX-targetX) <= d/2 && Math.abs(mouseY - targetY) <= d/2 && dist(x,y,mouse.getX(),mouse.getY()) <= d/2 )
            return '200,0,0';
        else
            return r+','+g+','+b;
    }

    function a() {
        var aliveTime = Date.now() - createTime;

        if( aliveTime <= fadeInTime){
            return aliveTime/fadeInTime;
        }

        if( fadeInTime <= aliveTime && aliveTime <= fadeInTime+fadeOffTime){
            return 1;
        }

        if( fadeInTime+fadeOffTime <= aliveTime && aliveTime <= fadeInTime+fadeOffTime+fadeOutTime){
            return (fadeInTime+fadeOffTime+fadeOutTime - aliveTime) / fadeOutTime;
        }

        return 0;
    }
}