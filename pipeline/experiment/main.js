$(document).ready( function () {            
    var canvas  = new Canvas(document.querySelector('#c'));

    if (!canvas.getContext2d) {
        return;//if canvas unsupported code here
    }
    
    //Too unreliable. Works very inconsistently from browser to browser.
    //window.addEventListener('unload', function() { return "abcd"; });
    //window.addEventListener('beforeunload', function() { return "Dude, are you sure you want to refresh? Think of the kittens!"; });
    
    var timer   = new Timer(true);
    var mouse   = new Mouse(canvas);    
    var targets = new Targets(mouse);
    var count   = new Count();
    
    var participant = new Participant();
    var experiment  = new Experiment(participant);
    
    var dialog1 = $( "#dialog1" );
    var dialog2 = $( "#dialog2" );
    var dialog3 = $( "#dialog3" );   
    
    canvas.draw = function(canvas) {
        targets.draw(canvas);
        timer.draw(canvas);
        count.draw(canvas);
    };
    
    var startAnimation = function() {
        count.startCounting();
        mouse.startTracking();
        canvas.startAnimating();
        targets.startAppearing();
    };
    
    var startExperiment = function () {
        timer.startTiming();
        experiment.beginExperiment();
    }
    
    var stopEverything = function() {        
        timer.stopTiming();
        count.stopCounting();
        mouse.stopTracking();
        canvas.stopAnimating();
        targets.stopAppearing();
        experiment.endExperiment();
        dialog3.dialog("open");
    };
    
    count.stopAfter(    3, startExperiment);
    timer.stopAfter(10000, stopEverything);
    
    dialog1.dialog({ 
        autoOpen   : false , 
        modal      : true  ,
        draggable  : false ,
        dialogClass: "no-x",
        buttons    : [
            { text: "Next", click: function() { dialog1.dialog( "close" ); dialog2.dialog("open");} }
        ]
    });
    
    dialog2.dialog({ 
        autoOpen   : false , 
        modal      : true  ,
        draggable  : false ,
        dialogClass: "no-x",
        buttons    : [
            { text: "Begin", click: function() { dialog2.dialog("close"); startAnimation(); } }
        ]
    });
    
    dialog3.dialog({
        autoOpen   : false , 
        modal      : true  ,
        draggable  : false ,
        dialogClass: "no-x",
        buttons    : [
            { text: "Repeat" , click: function() { dialog3.dialog("close"); startAnimation(); } },
            { text: "Updates", click: function() {  } }
        ]
    });
    
    dialog1.dialog("open");
    
});